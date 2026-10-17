#include "app/taskmanager.h"

#include "adapter/processrunner.h"
#include "app/apppaths.h"
#include "app/logmodel.h"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QTextStream>
#include <QUuid>

#include <algorithm>

namespace hyps {

struct TaskContext
{
    ProcessRunner *runner = nullptr;
    QFile logFile;
    QString partial[2];
    bool finished = false;
};

namespace {

QString stateId(Task::State state)
{
    switch (state) {
    case Task::State::Running:
        return QStringLiteral("running");
    case Task::State::Succeeded:
        return QStringLiteral("succeeded");
    case Task::State::Failed:
        return QStringLiteral("failed");
    case Task::State::Canceled:
        return QStringLiteral("canceled");
    case Task::State::TimedOut:
        return QStringLiteral("timeout");
    }
    return QStringLiteral("failed");
}

Task::State stateFromId(const QString &id)
{
    if (id == QLatin1String("running")) {
        return Task::State::Running;
    }
    if (id == QLatin1String("succeeded")) {
        return Task::State::Succeeded;
    }
    if (id == QLatin1String("canceled")) {
        return Task::State::Canceled;
    }
    if (id == QLatin1String("timeout")) {
        return Task::State::TimedOut;
    }
    return Task::State::Failed;
}

QString sanitizeForFileName(const QString &value)
{
    QString result = value;
    result.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9._-]")), QStringLiteral("-"));
    return result;
}

QString firstMeaningfulLine(const QString &text)
{
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\\r\\n]")),
                                         Qt::SkipEmptyParts);
    for (auto it = lines.crbegin(); it != lines.crend(); ++it) {
        const QString line = it->trimmed();
        if (line.isEmpty()) {
            continue;
        }
        // 过滤上游日志前缀后仍然保留可读信息。
        QString cleaned = line;
        static const QRegularExpression prefix(
                QStringLiteral("^\\[[^\\]]*\\]\\s*(?:\\[[A-Z]+\\]\\s*)?(?:\\[[^\\]]*\\]\\s*)?"));
        cleaned.remove(prefix);
        return cleaned.isEmpty() ? line : cleaned;
    }
    return {};
}

} // namespace

TaskListModel::TaskListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int TaskListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_tasks.size());
}

QVariant TaskListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tasks.size()) {
        return {};
    }
    Task *task = m_tasks.at(index.row());
    switch (role) {
    case IdRole:
        return task->id();
    case KindRole:
        return task->kind();
    case LabelRole:
        return task->label();
    case StateRole:
        return task->stateId();
    case StateTextRole:
        return task->stateText();
    case StartedRole:
        return task->startedAt();
    case FinishedRole:
        return task->finishedAt();
    case DurationRole:
        return task->durationText();
    case ExitCodeRole:
        return task->exitCode();
    case HasExitRole:
        return task->hasExitCode();
    case CommandRole:
        return task->command();
    case ErrorRole:
        return task->errorSummary();
    case ActiveRole:
        return task->active();
    case LogPathRole:
        return task->logPath();
    case DetailRole:
        return task->detail();
    default:
        return {};
    }
}

QHash<int, QByteArray> TaskListModel::roleNames() const
{
    return {
        {IdRole, QByteArrayLiteral("taskId")},
        {KindRole, QByteArrayLiteral("kind")},
        {LabelRole, QByteArrayLiteral("label")},
        {StateRole, QByteArrayLiteral("state")},
        {StateTextRole, QByteArrayLiteral("stateText")},
        {StartedRole, QByteArrayLiteral("startedAt")},
        {FinishedRole, QByteArrayLiteral("finishedAt")},
        {DurationRole, QByteArrayLiteral("durationText")},
        {ExitCodeRole, QByteArrayLiteral("exitCode")},
        {HasExitRole, QByteArrayLiteral("hasExitCode")},
        {CommandRole, QByteArrayLiteral("command")},
        {ErrorRole, QByteArrayLiteral("errorSummary")},
        {ActiveRole, QByteArrayLiteral("active")},
        {LogPathRole, QByteArrayLiteral("logPath")},
        {DetailRole, QByteArrayLiteral("detail")},
    };
}

void TaskListModel::addTask(Task *task)
{
    beginInsertRows(QModelIndex(), 0, 0);
    m_tasks.prepend(task);
    endInsertRows();
    emit countChanged();
}

void TaskListModel::removeTask(Task *task)
{
    const int row = rowOf(task);
    if (row < 0) {
        return;
    }
    beginRemoveRows(QModelIndex(), row, row);
    m_tasks.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

Task *TaskListModel::taskAt(int row) const
{
    if (row < 0 || row >= m_tasks.size()) {
        return nullptr;
    }
    return m_tasks.at(row);
}

int TaskListModel::rowOf(Task *task) const
{
    return static_cast<int>(m_tasks.indexOf(task));
}

void TaskListModel::notifyTask(Task *task)
{
    const int row = rowOf(task);
    if (row < 0) {
        return;
    }
    emit dataChanged(index(row, 0), index(row, 0));
}

TaskManager::TaskManager(AppPaths *paths, QObject *parent)
    : QObject(parent)
    , m_paths(paths)
    , m_model(new TaskListModel(this))
{
    QDir().mkpath(m_paths->tasksLogDir());
    QDir().mkpath(m_paths->stateDir());
    loadHistory();
}

TaskManager::~TaskManager()
{
    for (TaskContext *context : std::as_const(m_contexts)) {
        if (context->runner) {
            context->runner->cancel();
        }
        if (context->logFile.isOpen()) {
            context->logFile.close();
        }
        delete context;
    }
    m_contexts.clear();
}

void TaskManager::loadHistory()
{
    QFile file(m_paths->taskHistoryFile());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }

    QVector<Task *> history;
    QTextStream stream(&file);
    stream.setEncoding(QStringConverter::Utf8);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.isEmpty()) {
            continue;
        }
        const QJsonDocument document = QJsonDocument::fromJson(line.toUtf8());
        if (!document.isObject()) {
            continue;
        }
        const QJsonObject object = document.object();
        const QString id = object.value(QStringLiteral("id")).toString();
        if (id.isEmpty()) {
            continue;
        }
        const QString kind = object.value(QStringLiteral("kind")).toString();
        const QString label = object.value(QStringLiteral("label")).toString();
        const QString command = object.value(QStringLiteral("command")).toString();
        const QString logPath = object.value(QStringLiteral("logPath")).toString();
        const QString detail = object.value(QStringLiteral("detail")).toString();

        auto *task = new Task(id, kind, label, command, logPath, detail, this);
        task->setProbe(object.value(QStringLiteral("probe")).toBool(false));
        const Task::State state =
                stateFromId(object.value(QStringLiteral("state")).toString());
        const QDateTime started =
                QDateTime::fromString(object.value(QStringLiteral("startedAt")).toString(),
                                      Qt::ISODateWithMs);
        const QDateTime finished =
                QDateTime::fromString(object.value(QStringLiteral("finishedAt")).toString(),
                                      Qt::ISODateWithMs);
        task->markLoadedFromHistory(state, started, finished,
                                    object.value(QStringLiteral("exitCode")).toInt(),
                                    object.value(QStringLiteral("hasExitCode")).toBool(),
                                    object.value(QStringLiteral("error")).toString());
        history.append(task);
    }

    // 从旧到新依次 prepend，得到「最新在前」。
    for (Task *task : std::as_const(history)) {
        m_model->addTask(task);
        connect(task, &Task::changed, this, [this, task]() { m_model->notifyTask(task); });
    }

    pruneHistoryModel();
    if (m_model->rowCount() > 0) {
        setCurrentTask(m_model->taskAt(0));
    }
}

void TaskManager::pruneHistoryModel()
{
    constexpr int maxEntries = 200;
    while (m_model->rowCount() > maxEntries) {
        Task *task = m_model->taskAt(m_model->rowCount() - 1);
        if (task->active()) {
            break;
        }
        m_model->removeTask(task);
        task->deleteLater();
    }
}

Task *TaskManager::run(const TaskSpec &spec)
{
    const QString id = QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    const QString fileName = QStringLiteral("%1-%2-%3.log")
                                     .arg(stamp, sanitizeForFileName(spec.kind), id);
    const QString logPath = m_paths->tasksLogDir() + QLatin1Char('/') + fileName;

    const QString command = ProcessRunner::formatCommand(spec.program, spec.arguments);
    auto *task = new Task(id, spec.kind, spec.label, command, logPath, spec.detail, this);
    task->setProbe(spec.probe);
    task->setStartedAt(QDateTime::currentDateTime());

    auto *context = new TaskContext;
    m_contexts.insert(id, context);

    QString logError;
    QDir().mkpath(QFileInfo(logPath).absolutePath());
    context->logFile.setFileName(logPath);
    if (context->logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream stream(&context->logFile);
        stream.setEncoding(QStringConverter::Utf8);
        stream << "# Hyps Hub 任务日志\n";
        stream << "# kind: " << spec.kind << "\n";
        stream << "# label: " << spec.label << "\n";
        stream << "# command: " << command << "\n";
        stream << "# workdir: " << spec.workingDirectory << "\n";
        stream << "# started: " << QDateTime::currentDateTime().toString(Qt::ISODateWithMs)
               << "\n";
        stream.flush();
    } else {
        logError = tr("无法写入任务日志 %1：%2").arg(logPath, context->logFile.errorString());
        task->appendStderrTail(logError);
        task->setErrorSummary(logError);
    }

    m_model->addTask(task);
    connect(task, &Task::changed, this, [this, task]() {
        m_model->notifyTask(task);
        emit recentTasksChanged();
    });
    setCurrentTask(task);

    auto *runner = new ProcessRunner(task);
    context->runner = runner;

    emit taskStarted(task);
    emit activeCountChanged();
    emit recentTasksChanged();

    connect(runner, &ProcessRunner::started, task, [this, task, runner]() {
        writeMetaLine(task, QStringLiteral("进程已启动，PID %1").arg(runner->processId()));
        task->log()->appendLine(tr("进程已启动（PID %1）").arg(runner->processId()),
                                LogModel::System);
    });
    connect(runner, &ProcessRunner::standardOutput, task,
            [this, task](const QString &text) {
                task->appendCapturedStdout(text);
                task->log()->appendChunk(text, LogModel::Stdout);
                writeStream(task, LogModel::Stdout, text);
            });
    connect(runner, &ProcessRunner::standardError, task,
            [this, task](const QString &text) {
                task->appendStderrTail(text);
                task->log()->appendChunk(text, LogModel::Stderr);
                writeStream(task, LogModel::Stderr, text);
            });
    connect(runner, &ProcessRunner::failedToStart, task,
            [this, task](const QString &message) {
                task->log()->appendLine(message, LogModel::System);
                finalizeTask(task, Task::State::Failed, -1, false, message);
            });
    connect(runner, &ProcessRunner::finished, task,
            [this, task, spec](int exitCode, QProcess::ExitStatus exitStatus, bool canceled,
                               bool timedOut) {
                flushStreams(task);
                QString summary;
                if (canceled) {
                    summary = timedOut ? tr("任务超时，已终止") : tr("任务被用户取消");
                } else if (exitStatus == QProcess::CrashExit) {
                    summary = tr("进程异常终止（信号中断）");
                } else if (exitCode != 0) {
                    const QString tail = firstMeaningfulLine(task->stderrTail());
                    summary = tail.isEmpty()
                            ? tr("命令退出码 %1").arg(exitCode)
                            : tr("退出码 %1：%2").arg(exitCode).arg(tail);
                }

                Task::State state = Task::State::Succeeded;
                if (canceled) {
                    state = timedOut ? Task::State::TimedOut : Task::State::Canceled;
                } else if (exitStatus == QProcess::CrashExit) {
                    state = Task::State::Failed;
                } else if (exitCode != 0) {
                    state = spec.probe ? Task::State::Succeeded : Task::State::Failed;
                }
                finalizeTask(task, state, exitCode, exitStatus == QProcess::NormalExit, summary);
            });

    if (!runner->start(spec.program, spec.arguments, spec.workingDirectory, spec.environment,
                       spec.timeoutMs)) {
        const QString message = tr("无法启动任务：执行器状态异常");
        task->appendStderrTail(message);
        finalizeTask(task, Task::State::Failed, -1, false, message);
    }
    return task;
}

void TaskManager::writeMetaLine(Task *task, const QString &line)
{
    writeStream(task, LogModel::System, line + QLatin1Char('\n'));
}

void TaskManager::writeStream(Task *task, int stream, const QString &chunk)
{
    TaskContext *context = m_contexts.value(task->id(), nullptr);
    if (!context || !context->logFile.isOpen()) {
        return;
    }
    const int index = (stream == LogModel::Stderr) ? 1 : 0;
    const bool isSystem = (stream == LogModel::System);
    context->partial[index] += chunk;

    QTextStream streamWriter(&context->logFile);
    streamWriter.setEncoding(QStringConverter::Utf8);

    QString &buffer = context->partial[index];
    int start = 0;
    for (int i = 0; i < buffer.size(); ++i) {
        const QChar ch = buffer.at(i);
        if (ch == QLatin1Char('\n') || ch == QLatin1Char('\r')) {
            if (i > start) {
                const QString prefix = isSystem ? QStringLiteral("[sys] ")
                                               : (stream == LogModel::Stderr
                                                          ? QStringLiteral("[err] ")
                                                          : QStringLiteral("[out] "));
                streamWriter << prefix << buffer.mid(start, i - start) << "\n";
            }
            start = i + 1;
        }
    }
    buffer = buffer.mid(start);
    streamWriter.flush();
}

void TaskManager::flushStreams(Task *task)
{
    TaskContext *context = m_contexts.value(task->id(), nullptr);
    if (!context) {
        return;
    }
    for (int stream : {LogModel::Stdout, LogModel::Stderr}) {
        const int index = (stream == LogModel::Stderr) ? 1 : 0;
        if (!context->partial[index].isEmpty()) {
            writeStream(task, stream, QStringLiteral("\n"));
        }
    }
}

void TaskManager::finalizeTask(Task *task,
                               Task::State state,
                               int exitCode,
                               bool hasExitCode,
                               const QString &errorSummary)
{
    TaskContext *context = m_contexts.value(task->id(), nullptr);
    if (context) {
        if (context->finished) {
            return;
        }
        context->finished = true;

        if (context->logFile.isOpen()) {
            QTextStream stream(&context->logFile);
            stream.setEncoding(QStringConverter::Utf8);
            stream << "# finished: " << QDateTime::currentDateTime().toString(Qt::ISODateWithMs)
                   << "\n";
            stream << "# state: " << stateId(state) << "\n";
            stream << "# exit: " << exitCode << "\n";
            stream.flush();
            context->logFile.close();
        }
        removeContext(task->id());
    }

    task->setFinished(state, exitCode, hasExitCode);
    task->setErrorSummary(errorSummary);
    if (state == Task::State::Failed || state == Task::State::TimedOut) {
        setLastError(errorSummary.isEmpty() ? tr("任务失败：%1").arg(task->label())
                                            : errorSummary);
    }
    if (task->log()->totalCount() == 0) {
        task->log()->appendLine(tr("任务已结束：%1").arg(task->stateText()), LogModel::System);
    }
    appendHistory(*task);
    emit taskFinished(task);
    emit activeCountChanged();
    emit recentTasksChanged();
}

void TaskManager::removeContext(const QString &taskId)
{
    TaskContext *context = m_contexts.take(taskId);
    if (!context) {
        return;
    }
    if (context->logFile.isOpen()) {
        context->logFile.close();
    }
    delete context;
}

void TaskManager::select(const QString &taskId)
{
    if (Task *task = taskById(taskId)) {
        setCurrentTask(task);
        loadLogInto(task);
    }
}

Task *TaskManager::taskById(const QString &taskId) const
{
    for (Task *task : m_model->tasks()) {
        if (task->id() == taskId) {
            return task;
        }
    }
    return nullptr;
}

void TaskManager::setCurrentTask(Task *task)
{
    if (m_currentTask == task && !(task && !task->active()
                                   && task->log()->totalCount() == 0)) {
        return;
    }
    m_currentTask = task;
    emit currentTaskChanged();

    // 历史任务在重启后没有内存日志，切换时按需从磁盘载入，避免日志页空白。
    if (task && !task->active() && task->log()->totalCount() == 0) {
        loadLogInto(task);
    }
}

int TaskManager::activeCount() const
{
    int count = 0;
    for (Task *task : m_model->tasks()) {
        if (task->active()) {
            ++count;
        }
    }
    return count;
}

QVariantList TaskManager::recentTasks() const
{
    QVariantList list;
    const auto tasks = m_model->tasks();
    const int limit = qMin(8, static_cast<int>(tasks.size()));
    for (int i = 0; i < limit; ++i) {
        Task *task = tasks.at(i);
        QVariantMap map;
        map.insert(QStringLiteral("id"), task->id());
        map.insert(QStringLiteral("kind"), task->kind());
        map.insert(QStringLiteral("label"), task->label());
        map.insert(QStringLiteral("state"), task->stateId());
        map.insert(QStringLiteral("stateText"), task->stateText());
        map.insert(QStringLiteral("startedAt"), task->startedAt());
        map.insert(QStringLiteral("durationText"), task->durationText());
        map.insert(QStringLiteral("exitCode"), task->exitCode());
        map.insert(QStringLiteral("hasExitCode"), task->hasExitCode());
        map.insert(QStringLiteral("errorSummary"), task->errorSummary());
        map.insert(QStringLiteral("active"), task->active());
        list.append(map);
    }
    return list;
}

void TaskManager::cancelTask(const QString &taskId)
{
    TaskContext *context = m_contexts.value(taskId, nullptr);
    if (context && context->runner) {
        context->runner->cancel();
    }
}

void TaskManager::cancelActive()
{
    for (auto it = m_contexts.constBegin(); it != m_contexts.constEnd(); ++it) {
        if (it.value()->runner) {
            it.value()->runner->cancel();
        }
    }
}

void TaskManager::cancelAll()
{
    cancelActive();
}

void TaskManager::clearCurrentLogView()
{
    if (m_currentTask) {
        m_currentTask->log()->clear();
        m_currentTask->log()->appendLine(tr("已清空视图（磁盘日志保留）"), LogModel::System);
    }
}

void TaskManager::clearFinishedHistory()
{
    QVector<Task *> toRemove;
    for (Task *task : m_model->tasks()) {
        if (!task->active()) {
            toRemove.append(task);
        }
    }
    for (Task *task : toRemove) {
        m_model->removeTask(task);
        if (m_currentTask == task) {
            m_currentTask = nullptr;
        }
        task->deleteLater();
    }
    if (!m_currentTask && m_model->rowCount() > 0) {
        setCurrentTask(m_model->taskAt(0));
    } else if (m_currentTask == nullptr && m_model->rowCount() == 0) {
        emit currentTaskChanged();
    }

    if (QFile::exists(m_paths->taskHistoryFile())) {
        QFile::remove(m_paths->taskHistoryFile());
    }
    emit recentTasksChanged();
    emit activeCountChanged();
}

void TaskManager::loadLogInto(Task *task)
{
    if (!task || task->log()->totalCount() > 0 || task->logPath().isEmpty()) {
        return;
    }
    QFile file(task->logPath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    QTextStream stream(&file);
    stream.setEncoding(QStringConverter::Utf8);
    while (!stream.atEnd()) {
        const QString line = stream.readLine();
        if (line.startsWith(QLatin1Char('#'))) {
            continue;
        }
        if (line.startsWith(QLatin1String("[out] "))) {
            task->log()->appendLine(line.mid(6), LogModel::Stdout);
        } else if (line.startsWith(QLatin1String("[err] "))) {
            task->log()->appendLine(line.mid(6), LogModel::Stderr);
        } else if (line.startsWith(QLatin1String("[sys] "))) {
            task->log()->appendLine(line.mid(6), LogModel::System);
        } else if (!line.isEmpty()) {
            task->log()->appendLine(line, LogModel::Stdout);
        }
    }
}

void TaskManager::appendHistory(const Task &task)
{
    QJsonObject object;
    object.insert(QStringLiteral("id"), task.id());
    object.insert(QStringLiteral("kind"), task.kind());
    object.insert(QStringLiteral("label"), task.label());
    object.insert(QStringLiteral("command"), task.command());
    object.insert(QStringLiteral("detail"), task.detail());
    object.insert(QStringLiteral("state"), task.stateId());
    object.insert(QStringLiteral("startedAt"), task.startedAt().toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("finishedAt"), task.finishedAt().toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("exitCode"), task.exitCode());
    object.insert(QStringLiteral("hasExitCode"), task.hasExitCode());
    object.insert(QStringLiteral("error"), task.errorSummary());
    object.insert(QStringLiteral("logPath"), task.logPath());
    object.insert(QStringLiteral("probe"), task.probe());

    QFile file(m_paths->taskHistoryFile());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }
    file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
    file.write("\n");
    file.close();
    trimHistoryFile();
}

void TaskManager::trimHistoryFile()
{
    QFile file(m_paths->taskHistoryFile());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    const QStringList lines =
            QString::fromUtf8(file.readAll()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    file.close();
    constexpr int maxEntries = 200;
    if (lines.size() <= maxEntries) {
        return;
    }

    QSaveFile out(m_paths->taskHistoryFile());
    if (!out.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return;
    }
    const QStringList kept = lines.mid(lines.size() - maxEntries);
    for (const QString &line : kept) {
        out.write(line.toUtf8());
        out.write("\n");
    }
    out.commit();
}

void TaskManager::setLastError(const QString &message)
{
    if (m_lastError == message) {
        return;
    }
    m_lastError = message;
    emit lastErrorChanged();
}

} // namespace hyps
