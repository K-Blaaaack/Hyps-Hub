#include "runtime/runtimemanager.h"

#include "adapter/processrunner.h"
#include "app/apppaths.h"
#include "version.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>

#include <memory>

namespace hyps {

namespace {

QString tailLine(const QString &text)
{
    const QStringList lines =
            text.split(QRegularExpression(QStringLiteral("[\\r\\n]")), Qt::SkipEmptyParts);
    for (auto it = lines.crbegin(); it != lines.crend(); ++it) {
        const QString trimmed = it->trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }
        return trimmed.size() > 400 ? trimmed.left(400) + QStringLiteral("…") : trimmed;
    }
    return {};
}

QProcessEnvironment gitEnvironment()
{
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    // 避免在网络/认证异常时卡在交互式凭据提示上。
    environment.insert(QStringLiteral("GIT_TERMINAL_PROMPT"), QStringLiteral("0"));
    return environment;
}

bool commandAvailable(const QString &program)
{
    if (program.isEmpty()) {
        return false;
    }
    return !QStandardPaths::findExecutable(program).isEmpty();
}

} // namespace

RuntimeManager::RuntimeManager(AppPaths *paths, QObject *parent)
    : QObject(parent)
    , m_paths(paths)
    , m_repositoryUrl(QStringLiteral(HYPS_HUB_UPSTREAM_GIT_URL))
{
    readRuntimeInfo();
    m_state = QFileInfo::exists(runtimePath()) ? QStringLiteral("verifying")
                                              : QStringLiteral("missing");
    refreshPrerequisitesInternal();
}

QString RuntimeManager::runtimePath() const
{
    return m_paths ? m_paths->runtimeDir() : QString();
}

bool RuntimeManager::busy() const
{
    return m_cloneRunner != nullptr || m_commandRunner != nullptr
            || m_state == QLatin1String("cloning") || m_state == QLatin1String("updating");
}

void RuntimeManager::setState(const QString &state)
{
    if (m_state == state) {
        return;
    }
    m_state = state;
    emit stateChanged();
    emit busyChanged();
}

void RuntimeManager::setErrorMessage(const QString &message)
{
    if (m_errorMessage == message) {
        return;
    }
    m_errorMessage = message;
    emit errorMessageChanged();
}

void RuntimeManager::clearError()
{
    setErrorMessage(QString());
}

void RuntimeManager::setProgress(double value, const QString &text)
{
    const double clamped = qBound(0.0, value, 1.0);
    bool changed = false;
    if (!qFuzzyCompare(m_progress + 1.0, clamped + 1.0)) {
        m_progress = clamped;
        changed = true;
    }
    if (!text.isNull() && m_progressText != text) {
        m_progressText = text;
        changed = true;
    }
    if (changed) {
        emit progressChanged();
    }
}

void RuntimeManager::setNetworkStatus(const QString &status, const QString &detail)
{
    if (m_networkStatus == status && m_networkDetail == detail) {
        return;
    }
    m_networkStatus = status;
    m_networkDetail = detail;
    emit networkStatusChanged();
    refreshPrerequisitesInternal();
}

void RuntimeManager::appendLog(const QString &line)
{
    if (line.trimmed().isEmpty()) {
        return;
    }
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));
    m_logLines.append(QStringLiteral("[%1] %2").arg(stamp, line));
    while (m_logLines.size() > 400) {
        m_logLines.removeFirst();
    }
    emit logLinesChanged();
    appendRuntimeLogFile(line);
}

void RuntimeManager::appendRuntimeLogFile(const QString &line)
{
    if (!m_paths) {
        return;
    }
    QDir().mkpath(m_paths->logsDir());
    QFile file(m_paths->runtimeLogFile());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }
    const QString stamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    file.write(QStringLiteral("[%1] %2\n").arg(stamp, line).toUtf8());
}

void RuntimeManager::clearLogView()
{
    m_logLines.clear();
    emit logLinesChanged();
}

void RuntimeManager::readRuntimeInfo()
{
    QFile file(m_paths->runtimeInfoFile());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    QJsonParseError error{};
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error == QJsonParseError::NoError && document.isObject()) {
        m_info = document.object().toVariantMap();
    }
}

void RuntimeManager::writeRuntimeInfo(bool markInitialized, bool markUpdated)
{
    QJsonObject object = QJsonObject::fromVariantMap(m_info);
    object.insert(QStringLiteral("url"), m_repositoryUrl);
    object.insert(QStringLiteral("branch"), m_branch);
    object.insert(QStringLiteral("commit"), m_commit);
    object.insert(QStringLiteral("commitShort"), m_commitShort);
    object.insert(QStringLiteral("appVersion"), m_paths->appVersion());
    object.insert(QStringLiteral("runtimePath"), runtimePath());

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    object.insert(QStringLiteral("lastVerifiedAt"), now);
    if (markInitialized) {
        object.insert(QStringLiteral("initializedAt"), now);
    }
    if (markUpdated) {
        object.insert(QStringLiteral("lastUpdatedAt"), now);
    }

    QDir().mkpath(m_paths->dataDir());
    QSaveFile file(m_paths->runtimeInfoFile());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return;
    }
    file.write(QJsonDocument(object).toJson(QJsonDocument::Indented));
    if (file.commit()) {
        m_info = object.toVariantMap();
        emit infoChanged();
    }
}

void RuntimeManager::writeUpdateHistory(const QString &result, const QString &before,
                                        const QString &after, const QString &detail)
{
    QJsonObject object;
    object.insert(QStringLiteral("at"), QDateTime::currentDateTime().toString(Qt::ISODate));
    object.insert(QStringLiteral("result"), result);
    object.insert(QStringLiteral("before"), before);
    object.insert(QStringLiteral("after"), after);
    object.insert(QStringLiteral("branch"), m_branch);
    object.insert(QStringLiteral("detail"), detail);

    QDir().mkpath(m_paths->stateDir());
    QFile file(m_paths->updateHistoryFile());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }
    file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
    file.write("\n");
}

bool RuntimeManager::verifyStructure(const QString &directory, QStringList *missing)
{
    const QStringList requiredFiles = {
        QStringLiteral("config.conf"),
        QStringLiteral("init.sh"),
        QStringLiteral("scripts/_Hyps"),
        QStringLiteral("lib/libs.sh"),
        QStringLiteral("lib/common.sh"),
    };

    QStringList absent;
    for (const QString &relative : requiredFiles) {
        const QFileInfo info(directory + QLatin1Char('/') + relative);
        if (!info.exists() || !info.isFile() || !info.isReadable()) {
            absent.append(relative);
        }
    }
    if (missing) {
        *missing = absent;
    }
    return absent.isEmpty();
}

void RuntimeManager::runCommand(const QString &program, const QStringList &arguments,
                                const QString &workingDirectory, int timeoutMs,
                                OutputHandler onOutput, CommandDone done)
{
    auto *runner = new ProcessRunner(this);
    m_commandRunner = runner;
    emit busyChanged();

    auto out = std::make_shared<QString>();
    auto err = std::make_shared<QString>();

    connect(runner, &ProcessRunner::standardOutput, this,
            [out, onOutput](const QString &text) {
                *out += text;
                if (onOutput) {
                    onOutput(text, false);
                }
            });
    connect(runner, &ProcessRunner::standardError, this,
            [err, onOutput](const QString &text) {
                *err += text;
                if (onOutput) {
                    onOutput(text, true);
                }
            });
    connect(runner, &ProcessRunner::failedToStart, this,
            [this, runner, err, done](const QString &message) {
                if (m_commandRunner == runner) {
                    m_commandRunner = nullptr;
                }
                *err += message;
                runner->deleteLater();
                emit busyChanged();
                if (done) {
                    done(-1, QString(), message, false);
                }
            });
    connect(runner, &ProcessRunner::finished, this,
            [this, runner, out, err, done](int exitCode, QProcess::ExitStatus, bool canceled,
                                           bool) {
                if (m_commandRunner == runner) {
                    m_commandRunner = nullptr;
                }
                runner->deleteLater();
                emit busyChanged();
                if (done) {
                    done(exitCode, *out, *err, canceled);
                }
            });

    if (!runner->start(program, arguments, workingDirectory, gitEnvironment(), timeoutMs)) {
        m_commandRunner = nullptr;
        runner->deleteLater();
        emit busyChanged();
        if (done) {
            done(-1, QString(), tr("无法启动命令：%1").arg(program), false);
        }
    }
}

void RuntimeManager::runGit(const QStringList &arguments, int timeoutMs, OutputHandler onOutput,
                            CommandDone done)
{
    QStringList fullArguments{QStringLiteral("-C"), runtimePath()};
    fullArguments += arguments;
    runCommand(m_gitProgram, fullArguments, m_paths->dataDir(), timeoutMs, onOutput, done);
}

void RuntimeManager::loadGitInfo(std::function<void(bool, QString)> done)
{
    runGit({QStringLiteral("log"), QStringLiteral("-1"),
            QStringLiteral("--format=%H%x1f%h%x1f%s%x1f%cI")},
           20000, {},
           [this, done](int exitCode, const QString &out, const QString &err, bool canceled) {
               if (canceled) {
                   done(false, tr("操作已取消"));
                   return;
               }
               if (exitCode != 0) {
                   done(false, tr("无法读取 Git 信息：%1").arg(tailLine(err)));
                   return;
               }
               const QStringList fields = out.trimmed().split(QChar(0x1f));
               if (fields.size() < 4) {
                   done(false, tr("Git 输出格式无法识别"));
                   return;
               }
               m_commit = fields.at(0);
               m_commitShort = fields.at(1);
               m_commitSubject = fields.at(2);
               m_commitDate = fields.at(3);
               emit infoChanged();

               runGit({QStringLiteral("rev-parse"), QStringLiteral("--abbrev-ref"),
                       QStringLiteral("HEAD")},
                      10000, {},
                      [this, done](int branchCode, const QString &branchOut, const QString &err2,
                                   bool canceled2) {
                          if (canceled2) {
                              done(false, tr("操作已取消"));
                              return;
                          }
                          m_branch = (branchCode == 0) ? branchOut.trimmed()
                                                       : QStringLiteral("HEAD");
                          runGit({QStringLiteral("status"), QStringLiteral("--porcelain")},
                                 30000, {},
                                 [this, done](int statusCode, const QString &statusOut,
                                              const QString &err3, bool canceled3) {
                                     if (canceled3) {
                                         done(false, tr("操作已取消"));
                                         return;
                                     }
                                     if (statusCode != 0) {
                                         done(false,
                                              tr("无法读取 Git 工作区状态：%1")
                                                      .arg(tailLine(err3)));
                                         return;
                                     }
                                     m_dirty = !statusOut.trimmed().isEmpty();
                                     emit infoChanged();
                                     done(true, QString());
                                 });
                      });
           });
}

void RuntimeManager::refreshPrerequisitesInternal()
{
    QVariantList list;

    auto add = [&list](const QString &name, bool ok, const QString &detail,
                       const QString &hint) {
        QVariantMap item;
        item.insert(QStringLiteral("name"), name);
        item.insert(QStringLiteral("ok"), ok);
        item.insert(QStringLiteral("detail"), detail);
        item.insert(QStringLiteral("hint"), hint);
        list.append(item);
    };

    const QString gitPath = QStandardPaths::findExecutable(m_gitProgram);
    add(QStringLiteral("Git"), !gitPath.isEmpty(),
        gitPath.isEmpty() ? tr("未找到 git") : gitPath,
        tr("Arch: pacman -S git"));

    const QString bashPath = QStandardPaths::findExecutable(QStringLiteral("bash"));
    add(QStringLiteral("Bash"), !bashPath.isEmpty(),
        bashPath.isEmpty() ? tr("未找到 bash") : bashPath, tr("Arch: pacman -S bash"));

    QString dirError;
    const bool dirsOk = m_paths->ensureBaseDirectories(&dirError);
    add(QStringLiteral("数据目录"), dirsOk,
        dirsOk ? m_paths->dataDir() : dirError,
        tr("检查 $XDG_DATA_HOME 与目录权限"));

    add(QStringLiteral("网络"), m_networkStatus == QLatin1String("ok"),
        m_networkStatus == QLatin1String("ok")
                ? m_networkDetail
                : (m_networkStatus == QLatin1String("checking") ? tr("检查中…")
                                                                : tr("尚未检查")),
        tr("首次初始化需要访问 GitHub"));

    const QFileInfo runtimeInfo(runtimePath());
    QStringList missing;
    const bool runtimeValid =
            runtimeInfo.isDir() && RuntimeManager::verifyStructure(runtimePath(), &missing);
    add(QStringLiteral("Hyps 组件"), runtimeValid,
        !runtimeInfo.isDir() ? tr("尚未初始化")
                             : (runtimeValid ? runtimePath()
                                             : tr("目录存在但结构不完整（缺少 %1）")
                                                       .arg(missing.join(QStringLiteral("、")))),
        tr("首次启动会自动克隆到数据目录"));

    m_prerequisites = list;
    emit prerequisitesChanged();
}

void RuntimeManager::refreshPrerequisites()
{
    refreshPrerequisitesInternal();
}

void RuntimeManager::finishOperation()
{
    m_operation.clear();
    emit busyChanged();
}

void RuntimeManager::refresh()
{
    if (m_cloneRunner || m_commandRunner) {
        return;
    }
    clearError();
    m_operation = QStringLiteral("refresh");
    setState(QStringLiteral("verifying"));

    if (!QFileInfo::exists(runtimePath())) {
        if (QFileInfo::exists(m_paths->runtimeInfoFile())) {
            setState(QStringLiteral("invalid"));
            setErrorMessage(tr("存在初始化记录，但组件目录 %1 不存在。可重新初始化。")
                                    .arg(runtimePath()));
        } else {
            setState(QStringLiteral("missing"));
        }
        finishOperation();
        return;
    }

    QStringList missing;
    if (!verifyStructure(runtimePath(), &missing)) {
        setState(QStringLiteral("invalid"));
        setErrorMessage(tr("Hyps 组件不完整，缺少：%1").arg(missing.join(QStringLiteral("、"))));
        finishOperation();
        return;
    }

    if (!commandAvailable(m_gitProgram)) {
        setState(QStringLiteral("invalid"));
        setErrorMessage(tr("未找到 git，无法读取 Hyps 组件版本信息：%1").arg(m_gitProgram));
        finishOperation();
        return;
    }

    loadGitInfo([this](bool ok, QString error) {
        if (!ok) {
            setState(QStringLiteral("invalid"));
            setErrorMessage(error);
            finishOperation();
            return;
        }
        writeRuntimeInfo(false);
        setState(QStringLiteral("ready"));
        appendLog(tr("Hyps 组件就绪：%1 %2").arg(m_commitShort, m_commitSubject));
        emit stateChanged();
        finishOperation();
    });
}

void RuntimeManager::checkNetwork()
{
    if (m_commandRunner) {
        return;
    }
    m_operation = QStringLiteral("network");
    setNetworkStatus(QStringLiteral("checking"), tr("正在访问 %1 …").arg(m_repositoryUrl));
    runCommand(m_gitProgram,
               {QStringLiteral("ls-remote"), QStringLiteral("--exit-code"), m_repositoryUrl,
                QStringLiteral("HEAD")},
               m_paths->dataDir(), 20000, {},
               [this](int exitCode, const QString &out, const QString &err, bool canceled) {
                   if (canceled) {
                       setNetworkStatus(QStringLiteral("idle"), tr("网络检查已取消"));
                       return;
                   }
                   if (exitCode == 0) {
                       const QString hash = out.trimmed().section(QLatin1Char('\t'), 0, 0);
                       setNetworkStatus(QStringLiteral("ok"),
                                        tr("GitHub 可访问（HEAD %1）")
                                                .arg(hash.left(12)));
                   } else {
                       setNetworkStatus(QStringLiteral("error"),
                                        tr("无法访问上游仓库：%1").arg(tailLine(err)));
                   }
               });
}

void RuntimeManager::startClone()
{
    if (m_cloneRunner || m_commandRunner) {
        return;
    }
    clearError();
    m_operation = QStringLiteral("clone");

    if (QFileInfo::exists(runtimePath())) {
        QStringList missing;
        if (verifyStructure(runtimePath(), &missing)) {
            appendLog(tr("目标目录已存在有效的 Hyps 组件，跳过克隆"));
            refresh();
            emit initialized();
            return;
        }
        setState(QStringLiteral("invalid"));
        setErrorMessage(tr("目标目录已存在且不是有效的 Hyps 仓库：%1。未做任何修改，请手动检查该目录。")
                                .arg(runtimePath()));
        return;
    }

    if (!commandAvailable(m_gitProgram)) {
        setState(QStringLiteral("error"));
        setErrorMessage(tr("未找到 git，无法获取 Hyps 组件。请先安装 git。"));
        return;
    }

    QString dirError;
    if (!m_paths->ensureBaseDirectories(&dirError)) {
        setState(QStringLiteral("error"));
        setErrorMessage(dirError);
        return;
    }

    QString tempPath = m_paths->runtimeRoot() + QStringLiteral("/.Hyps.clone-")
            + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    int suffix = 1;
    while (QFileInfo::exists(tempPath)) {
        tempPath = m_paths->runtimeRoot()
                + QStringLiteral("/.Hyps.clone-")
                + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"))
                + QStringLiteral("-") + QString::number(suffix++);
    }
    m_cloneDirectory = tempPath;
    m_cloneBuffer.clear();
    m_cloneTail.clear();
    m_lastCloneLine.clear();
    m_clonePercentShown = -1;
    m_cloneCanceled = false;

    setState(QStringLiteral("cloning"));
    setProgress(0.0, tr("正在连接仓库…"));
    appendLog(tr("开始克隆 %1").arg(m_repositoryUrl));
    appendLog(tr("目标目录：%1").arg(runtimePath()));

    m_cloneRunner = new ProcessRunner(this);
    connect(m_cloneRunner, &ProcessRunner::standardOutput, this,
            [this](const QString &text) { handleCloneOutput(text); });
    connect(m_cloneRunner, &ProcessRunner::standardError, this,
            [this](const QString &text) { handleCloneOutput(text); });
    connect(m_cloneRunner, &ProcessRunner::failedToStart, this,
            [this](const QString &message) {
                appendLog(tr("启动 git clone 失败：%1").arg(message));
                cleanupCloneDirectory();
                setState(QStringLiteral("error"));
                setErrorMessage(tr("无法启动 git clone：%1").arg(message));
                m_cloneRunner = nullptr;
                finishOperation();
            });
    connect(m_cloneRunner, &ProcessRunner::finished, this,
            [this](int exitCode, QProcess::ExitStatus, bool canceled, bool timedOut) {
                handleCloneFinished(exitCode, canceled, timedOut);
            });

    if (!m_cloneRunner->start(m_gitProgram,
                              {QStringLiteral("clone"), QStringLiteral("--progress"),
                               m_repositoryUrl, tempPath},
                              m_paths->runtimeRoot(), gitEnvironment(), 0)) {
        appendLog(tr("无法启动 git clone"));
        cleanupCloneDirectory();
        setState(QStringLiteral("error"));
        setErrorMessage(tr("无法启动 git clone"));
        m_cloneRunner = nullptr;
        finishOperation();
    }
}

void RuntimeManager::handleCloneOutput(const QString &text)
{
    m_cloneBuffer += text;
    int start = 0;
    for (int i = 0; i < m_cloneBuffer.size(); ++i) {
        const QChar ch = m_cloneBuffer.at(i);
        if (ch == QLatin1Char('\r') || ch == QLatin1Char('\n')) {
            const QString line = m_cloneBuffer.mid(start, i - start);
            if (!line.trimmed().isEmpty()) {
                processCloneLine(line);
            }
            start = i + 1;
        }
    }
    m_cloneBuffer = m_cloneBuffer.mid(start);
    if (m_cloneBuffer.size() > 64 * 1024) {
        m_cloneBuffer = m_cloneBuffer.right(4096);
    }
}

void RuntimeManager::processCloneLine(const QString &rawLine)
{
    QString line = rawLine.trimmed();
    if (line.startsWith(QLatin1String("remote: "))) {
        line = line.mid(8).trimmed();
    }
    if (line.isEmpty()) {
        return;
    }
    m_cloneTail = line;

    static const QRegularExpression percentRe(QStringLiteral("(\\d{1,3})%"));
    const auto match = percentRe.match(line);
    const bool hasPercent = match.hasMatch();
    const int percent = hasPercent ? match.captured(1).toInt() : -1;

    double progress = m_progress;
    QString stage;
    if (line.contains(QLatin1String("Receiving objects"))) {
        stage = tr("接收对象");
        progress = hasPercent ? 0.15 + (percent / 100.0) * 0.75 : 0.15;
    } else if (line.contains(QLatin1String("Resolving deltas"))) {
        stage = tr("解析差异");
        progress = hasPercent ? 0.90 + (percent / 100.0) * 0.08 : 0.90;
    } else if (line.contains(QLatin1String("Updating files"))
               || line.contains(QLatin1String("Checking out files"))) {
        stage = tr("检出文件");
        progress = hasPercent ? 0.98 : 0.97;
    } else if (line.contains(QLatin1String("Counting objects"))
               || line.contains(QLatin1String("Enumerating objects"))) {
        stage = tr("统计对象");
        progress = qMax(progress, 0.05);
    } else if (line.contains(QLatin1String("Compressing objects"))) {
        stage = tr("压缩对象");
        progress = qMax(progress, 0.08);
    } else if (line.contains(QLatin1String("Cloning into"))) {
        stage = tr("正在连接");
        progress = qMax(progress, 0.02);
    } else if (line.contains(QLatin1String("Total "))) {
        stage = tr("传输完成");
        progress = qMax(progress, 0.14);
    }

    if (!stage.isEmpty()) {
        const QString text = QStringLiteral("%1…%2")
                                     .arg(stage,
                                          hasPercent ? QStringLiteral(" %1%").arg(percent)
                                                     : QString());
        setProgress(progress, text);

        const int bucket = percent >= 0 ? (percent / 10) * 10 : -1;
        const bool shouldLog = (m_clonePercentShown != bucket && percent >= 0)
                || (m_lastCloneLine != line && percent < 0);
        if (shouldLog) {
            m_clonePercentShown = bucket;
            m_lastCloneLine = line;
            appendLog(text);
        }
    } else if (m_lastCloneLine != line) {
        m_lastCloneLine = line;
        appendLog(line);
    }
}

void RuntimeManager::cleanupCloneDirectory()
{
    if (m_cloneDirectory.isEmpty()) {
        return;
    }
    const QString expectedPrefix = m_paths->runtimeRoot() + QStringLiteral("/.Hyps.clone-");
    if (!m_cloneDirectory.startsWith(expectedPrefix)) {
        appendLog(tr("拒绝清理非本次初始化创建的目录：%1").arg(m_cloneDirectory));
        m_cloneDirectory.clear();
        return;
    }
    if (QFileInfo::exists(m_cloneDirectory)) {
        QDir directory(m_cloneDirectory);
        if (directory.removeRecursively()) {
            appendLog(tr("已清理本次克隆的临时目录"));
        } else {
            appendLog(tr("临时目录清理失败：%1").arg(m_cloneDirectory));
        }
    }
    m_cloneDirectory.clear();
}

void RuntimeManager::handleCloneFinished(int exitCode, bool canceled, bool timedOut)
{
    if (m_cloneRunner) {
        m_cloneRunner->deleteLater();
        m_cloneRunner = nullptr;
    }
    emit busyChanged();

    if (canceled || m_cloneCanceled) {
        cleanupCloneDirectory();
        setState(QStringLiteral("missing"));
        setErrorMessage(tr("克隆已取消，未保留任何临时文件。"));
        setProgress(0.0, tr("已取消"));
        appendLog(tr("用户取消了克隆操作"));
        finishOperation();
        return;
    }
    if (timedOut) {
        cleanupCloneDirectory();
        setState(QStringLiteral("error"));
        setErrorMessage(tr("克隆超时，未保留任何临时文件。"));
        finishOperation();
        return;
    }
    if (exitCode != 0) {
        const QString detail = m_cloneTail.isEmpty() ? tr("未知错误") : m_cloneTail;
        cleanupCloneDirectory();
        setState(QStringLiteral("error"));
        setErrorMessage(tr("克隆失败（退出码 %1）：%2").arg(exitCode).arg(detail));
        setProgress(0.0, tr("克隆失败"));
        appendLog(tr("克隆失败（退出码 %1）：%2").arg(exitCode).arg(detail));
        finishOperation();
        return;
    }

    QStringList missing;
    if (!verifyStructure(m_cloneDirectory, &missing)) {
        cleanupCloneDirectory();
        setState(QStringLiteral("error"));
        setErrorMessage(tr("克隆完成但仓库结构不完整，缺少：%1。已清理临时目录。")
                                .arg(missing.join(QStringLiteral("、"))));
        finishOperation();
        return;
    }

    if (QFileInfo::exists(runtimePath())) {
        cleanupCloneDirectory();
        setState(QStringLiteral("invalid"));
        setErrorMessage(tr("目标目录已被其他程序创建，已放弃本次克隆结果（未覆盖任何文件）。"));
        finishOperation();
        return;
    }

    const QString temp = m_cloneDirectory;
    if (!QDir().rename(temp, runtimePath())) {
        const QString message = tr("无法把临时目录移动到 %1。临时目录保留在 %2。")
                                        .arg(runtimePath(), temp);
        setState(QStringLiteral("error"));
        setErrorMessage(message);
        appendLog(message);
        m_cloneDirectory.clear();
        finishOperation();
        return;
    }
    m_cloneDirectory.clear();

    setState(QStringLiteral("verifying"));
    setProgress(0.95, tr("克隆完成，正在校验 Hyps 组件…"));
    appendLog(tr("克隆完成，开始校验 Hyps 组件"));

    loadGitInfo([this](bool ok, QString error) {
        if (!ok) {
            setState(QStringLiteral("error"));
            setErrorMessage(tr("克隆完成但校验失败：%1").arg(error));
            setProgress(1.0, tr("初始化失败"));
            finishOperation();
            return;
        }
        writeRuntimeInfo(true);
        setState(QStringLiteral("ready"));
        setProgress(1.0, tr("初始化完成"));
        appendLog(tr("Hyps 组件初始化完成：%1 %2").arg(m_commitShort, m_commitSubject));
        emit initialized();
        finishOperation();
    });
}

QString RuntimeManager::defaultBranchName() const
{
    if (m_branch.isEmpty() || m_branch == QLatin1String("HEAD")) {
        return QStringLiteral("main");
    }
    return m_branch;
}

void RuntimeManager::checkForUpdates()
{
    if (!ready() || m_commandRunner || m_cloneRunner) {
        return;
    }
    m_updateStatusText = tr("正在获取上游信息…");
    emit updateStateChanged();
    m_operation = QStringLiteral("fetch");
    appendLog(tr("检查更新：git fetch --prune origin"));

    runGit({QStringLiteral("fetch"), QStringLiteral("--prune"), QStringLiteral("origin")},
           180000, {},
           [this](int exitCode, const QString &, const QString &err, bool canceled) {
               if (canceled) {
                   m_updateStatusText = tr("检查更新已取消");
                   emit updateStateChanged();
                   finishOperation();
                   return;
               }
               if (exitCode != 0) {
                   m_updateStatusText =
                           tr("获取上游信息失败：%1").arg(tailLine(err));
                   appendLog(m_updateStatusText);
                   emit updateStateChanged();
                   finishOperation();
                   return;
               }

               runGit({QStringLiteral("status"), QStringLiteral("--porcelain")}, 30000, {},
                      [this](int statusCode, const QString &statusOut, const QString &,
                             bool statusCanceled) {
                          if (statusCanceled) {
                              m_updateStatusText = tr("检查更新已取消");
                              emit updateStateChanged();
                              finishOperation();
                              return;
                          }
                          if (statusCode == 0) {
                              m_dirty = !statusOut.trimmed().isEmpty();
                              emit infoChanged();
                          }

                          const QString branchName = defaultBranchName();
                          const QString remoteRef =
                                  QStringLiteral("refs/remotes/origin/") + branchName;
                          runGit({QStringLiteral("rev-parse"), QStringLiteral("--verify"),
                                  QStringLiteral("--quiet"), remoteRef},
                                 10000, {},
                                 [this, branchName](int verifyCode, const QString &,
                                                    const QString &, bool verifyCanceled) {
                                     if (verifyCanceled) {
                                         m_updateStatusText = tr("检查更新已取消");
                                         emit updateStateChanged();
                                         finishOperation();
                                         return;
                                     }
                                     if (verifyCode != 0) {
                                         m_updateAvailable = false;
                                         m_updateStatusText =
                                                 tr("当前分支 '%1' 没有对应的远程分支，无法自动更新。")
                                                         .arg(branchName);
                                         emit updateStateChanged();
                                         finishOperation();
                                         return;
                                     }

                                     runGit({QStringLiteral("log"), QStringLiteral("-1"),
                                             QStringLiteral("--format=%H%x1f%s%x1f%cI"),
                                             QStringLiteral("origin/") + branchName},
                                            20000, {},
                                            [this, branchName](int logCode, const QString &logOut,
                                                               const QString &logErr,
                                                               bool logCanceled) {
                                                if (logCanceled) {
                                                    m_updateStatusText = tr("检查更新已取消");
                                                    emit updateStateChanged();
                                                    finishOperation();
                                                    return;
                                                }
                                                if (logCode != 0) {
                                                    m_updateStatusText =
                                                            tr("无法读取上游提交信息：%1")
                                                                    .arg(tailLine(logErr));
                                                    emit updateStateChanged();
                                                    finishOperation();
                                                    return;
                                                }
                                                const QStringList fields =
                                                        logOut.trimmed().split(QChar(0x1f));
                                                if (fields.size() >= 3) {
                                                    m_upstreamCommit = fields.at(0);
                                                    m_upstreamSubject = fields.at(1);
                                                    m_upstreamDate = fields.at(2);
                                                }

                                                runGit({QStringLiteral("rev-list"),
                                                        QStringLiteral("--left-right"),
                                                        QStringLiteral("--count"),
                                                        QStringLiteral("HEAD...origin/")
                                                                + branchName},
                                                       20000, {},
                                                       [this](int countCode, const QString &countOut,
                                                              const QString &countErr,
                                                              bool countCanceled) {
                                                           if (countCanceled) {
                                                               m_updateStatusText =
                                                                       tr("检查更新已取消");
                                                               emit updateStateChanged();
                                                               finishOperation();
                                                               return;
                                                           }
                                                           if (countCode != 0) {
                                                               m_updateStatusText =
                                                                       tr("无法比较提交：%1")
                                                                               .arg(tailLine(countErr));
                                                               emit updateStateChanged();
                                                               finishOperation();
                                                               return;
                                                           }
                                                           const QStringList counts =
                                                                   countOut.trimmed().split(
                                                                           QRegularExpression(
                                                                                   QStringLiteral(
                                                                                           "\\s+")),
                                                                           Qt::SkipEmptyParts);
                                                           m_aheadCount =
                                                                   counts.size() > 0
                                                                   ? counts.at(0).toInt()
                                                                   : 0;
                                                           m_behindCount =
                                                                   counts.size() > 1
                                                                   ? counts.at(1).toInt()
                                                                   : 0;
                                                           m_updateAvailable = m_behindCount > 0;

                                                           if (m_updateAvailable) {
                                                               m_updateStatusText =
                                                                       tr("有 %1 个新提交可更新")
                                                                               .arg(m_behindCount);
                                                           } else {
                                                               m_updateStatusText =
                                                                       tr("已是最新");
                                                           }
                                                           if (m_aheadCount > 0) {
                                                               m_updateStatusText +=
                                                                       tr("（本地领先 %1 个提交，仅支持快进更新）")
                                                                               .arg(m_aheadCount);
                                                           }
                                                           if (m_dirty) {
                                                               m_updateStatusText +=
                                                                       tr("；Hyps 组件有未提交修改，更新会被阻止");
                                                           }
                                                           appendLog(tr("检查更新完成：%1")
                                                                             .arg(m_updateStatusText));
                                                           emit updateStateChanged();
                                                           finishOperation();
                                                       });
                                            });
                                 });
                      });
           });
}

void RuntimeManager::applyUpdate()
{
    if (!ready() || m_commandRunner || m_cloneRunner) {
        return;
    }
    if (!m_updateAvailable) {
        m_updateStatusText = tr("没有可用更新");
        emit updateStateChanged();
        return;
    }

    const QString branchName = defaultBranchName();
    m_operation = QStringLiteral("update");
    setState(QStringLiteral("updating"));
    setProgress(0.1, tr("检查工作区状态…"));
    appendLog(tr("开始更新：origin/%1").arg(branchName));

    runGit({QStringLiteral("status"), QStringLiteral("--porcelain")}, 30000, {},
           [this, branchName](int statusCode, const QString &statusOut, const QString &statusErr,
                              bool canceled) {
               if (canceled) {
                   setState(QStringLiteral("ready"));
                   m_updateStatusText = tr("更新已取消（未做任何更改）");
                   setProgress(0.0, QString());
                   emit updateStateChanged();
                   finishOperation();
                   return;
               }
               if (statusCode != 0) {
                   setState(QStringLiteral("ready"));
                   m_updateStatusText =
                           tr("无法检查工作区状态：%1").arg(tailLine(statusErr));
                   setProgress(0.0, QString());
                   emit updateStateChanged();
                   finishOperation();
                   return;
               }
               if (!statusOut.trimmed().isEmpty()) {
                   m_dirty = true;
                   emit infoChanged();
                   setState(QStringLiteral("ready"));
                   m_updateStatusText =
                           tr("Hyps 组件有未提交修改，已停止更新（未做任何更改）。请先手动处理这些修改。");
                   setProgress(0.0, QString());
                   appendLog(m_updateStatusText);
                   emit updateStateChanged();
                   finishOperation();
                   return;
               }

               const QString before = m_commit;
               setProgress(0.35, tr("正在快进合并 origin/%1…").arg(branchName));
               runGit({QStringLiteral("merge"), QStringLiteral("--ff-only"),
                       QStringLiteral("origin/") + branchName},
                      180000, {},
                      [this, before, branchName](int mergeCode, const QString &,
                                                 const QString &mergeErr, bool mergeCanceled) {
                          if (mergeCanceled) {
                              setState(QStringLiteral("ready"));
                              m_updateStatusText =
                                      tr("更新过程被中断，请检查 Hyps 组件状态（GUI 未执行任何重置）。");
                              setProgress(0.0, QString());
                              appendLog(m_updateStatusText);
                              emit updateStateChanged();
                              emit updateFinished(false);
                              finishOperation();
                              return;
                          }
                          if (mergeCode != 0) {
                              setState(QStringLiteral("ready"));
                              const QString detail = tailLine(mergeErr);
                              m_updateStatusText =
                                      tr("更新失败（未执行 reset/clean）：%1").arg(detail);
                              setProgress(0.0, QString());
                              appendLog(m_updateStatusText);
                              writeUpdateHistory(QStringLiteral("failed"), before, m_commit,
                                                 detail);
                              emit updateStateChanged();
                              emit updateFinished(false);
                              finishOperation();
                              return;
                          }

                          QStringList missing;
                          if (!verifyStructure(runtimePath(), &missing)) {
                              setState(QStringLiteral("ready"));
                              const QString detail = tr("更新后缺少：%1")
                                                             .arg(missing.join(QStringLiteral("、")));
                              m_updateStatusText =
                                      tr("更新已合并，但校验失败（%1）。建议在诊断页导出日志并检查组件目录。")
                                              .arg(detail);
                              setProgress(0.0, QString());
                              appendLog(m_updateStatusText);
                              writeUpdateHistory(QStringLiteral("failed"), before, m_commit,
                                                 detail);
                              emit updateStateChanged();
                              emit updateFinished(false);
                              finishOperation();
                              return;
                          }

                          setProgress(0.8, tr("更新完成，正在校验…"));
                          loadGitInfo([this, before](bool ok, QString error) {
                              if (!ok) {
                                  setState(QStringLiteral("ready"));
                                  m_updateStatusText =
                                          tr("更新已合并，但读取版本信息失败：%1").arg(error);
                                  setProgress(0.0, QString());
                                  appendLog(m_updateStatusText);
                                  writeUpdateHistory(QStringLiteral("failed"), before, m_commit,
                                                     error);
                                  emit updateStateChanged();
                                  emit updateFinished(false);
                                  finishOperation();
                                  return;
                              }
                              writeRuntimeInfo(false, true);
                              m_updateAvailable = false;
                              m_behindCount = 0;
                              m_updateStatusText =
                                      tr("已更新到 %1（%2）")
                                              .arg(m_commitShort, m_commitSubject);
                              setProgress(1.0, tr("更新完成"));
                              appendLog(m_updateStatusText);
                              writeUpdateHistory(QStringLiteral("ok"), before, m_commit,
                                                 QString());
                              emit updateStateChanged();
                              emit updateFinished(true);
                              setState(QStringLiteral("ready"));
                              finishOperation();
                          });
                      });
           });
}

void RuntimeManager::cancelOperation()
{
    if (m_cloneRunner) {
        m_cloneCanceled = true;
        m_cloneRunner->cancel();
        appendLog(tr("正在取消克隆…"));
        return;
    }
    if (m_commandRunner) {
        if (m_operation == QLatin1String("update")) {
            m_updateStatusText = tr("更新进行中，暂不支持中途取消，请等待完成。");
            emit updateStateChanged();
            return;
        }
        m_commandRunner->cancel();
    }
}

} // namespace hyps
