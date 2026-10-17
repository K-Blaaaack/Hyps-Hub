#include "adapter/hypsadapter.h"

#include "adapter/environmentreport.h"
#include "app/apppaths.h"
#include "app/task.h"
#include "app/taskmanager.h"
#include "runtime/runtimemanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTextStream>

namespace hyps {

namespace {

QString stripTail(const QString &text)
{
    const QStringList lines =
            text.split(QRegularExpression(QStringLiteral("[\\r\\n]")), Qt::SkipEmptyParts);
    for (auto it = lines.crbegin(); it != lines.crend(); ++it) {
        const QString trimmed = it->trimmed();
        if (!trimmed.isEmpty()) {
            return trimmed;
        }
    }
    return {};
}

} // namespace

HypsAdapter::HypsAdapter(AppPaths *paths, RuntimeManager *runtime, TaskManager *tasks,
                         EnvironmentReport *report, QObject *parent)
    : QObject(parent)
    , m_paths(paths)
    , m_runtime(runtime)
    , m_tasks(tasks)
    , m_report(report)
{
    connect(m_runtime, &RuntimeManager::stateChanged, this, [this]() {
        emit canRunChanged();
        if (m_runtime->ready()) {
            setLastError(QString());
        }
    });
    connect(m_runtime, &RuntimeManager::infoChanged, this, &HypsAdapter::canRunChanged);
}

QString HypsAdapter::cliEntryPoint() const
{
    return m_paths->cliEntryPoint();
}

bool HypsAdapter::canRun() const
{
    return m_runtime->ready() && QFileInfo(m_paths->cliEntryPoint()).isReadable();
}

QVariantList HypsAdapter::diagnosticActions() const
{
    auto action = [](const QString &id, const QString &title, const QString &description) {
        QVariantMap map;
        map.insert(QStringLiteral("id"), id);
        map.insert(QStringLiteral("title"), title);
        map.insert(QStringLiteral("description"), description);
        return map;
    };
    return {
        action(QStringLiteral("init-check"), QStringLiteral("环境检测"),
               QStringLiteral("执行 init.sh --check，结果同步到诊断报表")),
        action(QStringLiteral("cli-help"), QStringLiteral("CLI 帮助"),
               QStringLiteral("执行 scripts/_Hyps --help，验证 CLI 可用")),
        action(QStringLiteral("game-list"), QStringLiteral("游戏列表"),
               QStringLiteral("执行 scripts/_Hyps game list（原始输出）")),
        action(QStringLiteral("proton-list"), QStringLiteral("Proton 列表"),
               QStringLiteral("执行 scripts/_Hyps proton list（原始输出）")),
        action(QStringLiteral("time-list"), QStringLiteral("游玩时长"),
               QStringLiteral("执行 scripts/_Hyps time list（原始输出）")),
    };
}

QProcessEnvironment HypsAdapter::cliEnvironment(bool *ok)
{
    if (ok) {
        *ok = false;
    }
    QString error;
    if (!m_paths->ensureBaseDirectories(&error)) {
        setLastError(error);
        return {};
    }
    if (ok) {
        *ok = true;
    }
    return m_paths->hypsEnvironment();
}

bool HypsAdapter::runtimeUsable(QString *reason) const
{
    if (!m_runtime->ready()) {
        if (reason) {
            *reason = tr("Hyps 组件尚未就绪（当前状态：%1）").arg(m_runtime->state());
        }
        return false;
    }
    QStringList missing;
    if (!RuntimeManager::verifyStructure(m_paths->runtimeDir(), &missing)) {
        if (reason) {
            *reason = tr("Hyps 组件缺少文件：%1").arg(missing.join(QStringLiteral("、")));
        }
        return false;
    }
    if (!QFileInfo(m_paths->cliEntryPoint()).isReadable()) {
        if (reason) {
            *reason = tr("CLI 入口不可读：%1").arg(m_paths->cliEntryPoint());
        }
        return false;
    }
    return true;
}

Task *HypsAdapter::runCli(const QString &kind, const QString &label,
                          const QStringList &scriptArguments, int timeoutMs, bool probe,
                          const QString &detail)
{
    QString reason;
    if (!runtimeUsable(&reason)) {
        setLastError(reason);
        return nullptr;
    }
    if (scriptArguments.isEmpty()) {
        setLastError(tr("内部错误：没有指定脚本"));
        return nullptr;
    }

    bool envOk = false;
    const QProcessEnvironment environment = cliEnvironment(&envOk);
    if (!envOk) {
        return nullptr;
    }

    // 第一个参数是相对于 Hyps 组件根的脚本路径，其余是该脚本的参数。
    const QString script = m_paths->runtimeDir() + QLatin1Char('/') + scriptArguments.first();
    if (!QFileInfo(script).isFile()) {
        setLastError(tr("脚本不存在：%1").arg(script));
        return nullptr;
    }

    TaskSpec spec;
    spec.kind = kind;
    spec.label = label;
    spec.program = QStringLiteral("bash");
    spec.arguments = QStringList{script} + scriptArguments.mid(1);
    spec.workingDirectory = m_paths->runtimeDir();
    spec.environment = environment;
    spec.timeoutMs = timeoutMs;
    spec.probe = probe;
    spec.detail = detail;

    Task *task = m_tasks->run(spec);

    connect(m_tasks, &TaskManager::taskFinished, task, [this, task](Task *finished) {
        if (finished != task) {
            return;
        }
        if (task->state() == Task::State::Failed || task->state() == Task::State::TimedOut) {
            const QString detail = task->errorSummary().isEmpty()
                    ? tr("任务失败：%1").arg(task->label())
                    : task->errorSummary();
            setLastError(detail);
        }
    });
    return task;
}

Task *HypsAdapter::checkEnvironment()
{
    Task *task = runCli(QStringLiteral("diagnostics"), tr("环境检测"),
                        {QStringLiteral("init.sh"), QStringLiteral("--check")}, 120000, true);
    if (!task) {
        return nullptr;
    }

    connect(m_tasks, &TaskManager::taskFinished, task, [this, task](Task *finished) {
        if (finished != task) {
            return;
        }
        if (task->state() == Task::State::Canceled || task->state() == Task::State::TimedOut) {
            return;
        }
        const QString stdoutText = task->capturedStdout();
        if (stdoutText.trimmed().isEmpty()) {
            setLastError(tr("环境检测没有输出：%1").arg(task->errorSummary()));
            return;
        }
        m_report->parse(stdoutText);
        m_report->saveToFile(m_paths->envReportFile());
        setLastError(QString());
        emit environmentChecked();
    });
    return task;
}

Task *HypsAdapter::initializeConfig()
{
    Task *task = runCli(QStringLiteral("config"), tr("初始化 Hyps 配置"),
                        {QStringLiteral("init.sh"), QStringLiteral("--no-game")}, 300000, false);
    if (!task) {
        return nullptr;
    }
    connect(m_tasks, &TaskManager::taskFinished, task, [this, task](Task *finished) {
        if (finished == task && task->state() == Task::State::Succeeded) {
            setLastError(QString());
            emit configInitialized();
        }
    });
    return task;
}

Task *HypsAdapter::createGameConfig(const QString &slug)
{
    static const QRegularExpression validSlug(QStringLiteral("^[a-z0-9_]+$"));
    if (!validSlug.match(slug).hasMatch()) {
        setLastError(tr("非法的游戏名：%1").arg(slug));
        return nullptr;
    }
    Task *task = runCli(QStringLiteral("config"), tr("创建游戏配置：%1").arg(slug),
                        {QStringLiteral("init.sh"), slug}, 300000, false);
    if (!task) {
        return nullptr;
    }
    connect(m_tasks, &TaskManager::taskFinished, task, [this, task, slug](Task *finished) {
        if (finished == task && task->state() == Task::State::Succeeded) {
            setLastError(QString());
            emit gameConfigCreated(slug);
        }
    });
    return task;
}

Task *HypsAdapter::verifyCli()
{
    Task *task = runCli(QStringLiteral("diagnostics"), tr("CLI 自检"),
                        {QStringLiteral("scripts/_Hyps"), QStringLiteral("--help")}, 30000,
                        false);
    if (!task) {
        return nullptr;
    }
    connect(m_tasks, &TaskManager::taskFinished, task, [this, task](Task *finished) {
        if (finished != task) {
            return;
        }
        const bool ok = task->state() == Task::State::Succeeded;
        if (ok) {
            setLastError(QString());
        }
        if (m_cliVerified != ok) {
            m_cliVerified = ok;
            emit cliVerifiedChanged();
        }
    });
    return task;
}

Task *HypsAdapter::runDiagnostic(const QString &actionId)
{
    if (actionId == QLatin1String("init-check")) {
        return checkEnvironment();
    }
    if (actionId == QLatin1String("cli-help")) {
        return verifyCli();
    }
    if (actionId == QLatin1String("game-list")) {
        return runCli(QStringLiteral("diagnostics"), tr("游戏列表"),
                      {QStringLiteral("scripts/_Hyps"), QStringLiteral("game"),
                       QStringLiteral("list")},
                      60000, false);
    }
    if (actionId == QLatin1String("proton-list")) {
        return runCli(QStringLiteral("diagnostics"), tr("Proton 列表"),
                      {QStringLiteral("scripts/_Hyps"), QStringLiteral("proton"),
                       QStringLiteral("list")},
                      60000, false);
    }
    if (actionId == QLatin1String("time-list")) {
        return runCli(QStringLiteral("diagnostics"), tr("游玩时长"),
                      {QStringLiteral("scripts/_Hyps"), QStringLiteral("time"),
                       QStringLiteral("list")},
                      60000, false);
    }
    setLastError(tr("未授权的诊断命令：%1").arg(actionId));
    return nullptr;
}

QString HypsAdapter::findLauncherScript(const QString &slug) const
{
    const QDir scripts(m_paths->launcherScriptsDir());
    if (!scripts.exists()) {
        return {};
    }
    const QFileInfoList files =
            scripts.entryInfoList({QStringLiteral("*.sh")}, QDir::Files | QDir::Readable, QDir::Name);
    static const QRegularExpression nameRe(
            QStringLiteral("^\\s*GAME_NAME=\"?([^\"\\s]+)\"?\\s*$"),
            QRegularExpression::MultilineOption);

    for (const QFileInfo &file : files) {
        if (file.fileName().startsWith(QLatin1Char('_'))) {
            continue;
        }
        QFile script(file.absoluteFilePath());
        if (!script.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        const QString content = QString::fromUtf8(script.read(8192));
        const auto match = nameRe.match(content);
        if (match.hasMatch() && match.captured(1).trimmed() == slug) {
            return file.absoluteFilePath();
        }
    }
    return {};
}

QString HypsAdapter::launcherForSlug(const QString &slug) const
{
    return findLauncherScript(slug);
}

QVariantMap HypsAdapter::canLaunch(const QString &slug) const
{
    QVariantMap result;
    QString reason;
    if (!runtimeUsable(&reason)) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("reason"), reason);
        return result;
    }

    const QString configPath =
            m_paths->hypsConfigDir() + QStringLiteral("/games/") + slug
            + QStringLiteral(".conf");
    if (!QFileInfo::exists(configPath)) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("reason"), tr("尚未创建 %1.conf").arg(slug));
        return result;
    }

    const QString launcher = findLauncherScript(slug);
    if (launcher.isEmpty()) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("reason"), tr("在 scripts/ 中找不到 GAME_NAME=%1 的启动脚本")
                                                        .arg(slug));
        return result;
    }

    result.insert(QStringLiteral("ok"), true);
    result.insert(QStringLiteral("reason"), QString());
    result.insert(QStringLiteral("launcher"), launcher);
    result.insert(QStringLiteral("configPath"), configPath);
    return result;
}

Task *HypsAdapter::launchGame(const QString &slug, const QString &label)
{
    const QVariantMap check = canLaunch(slug);
    if (!check.value(QStringLiteral("ok")).toBool()) {
        setLastError(check.value(QStringLiteral("reason")).toString());
        return nullptr;
    }

    const QString launcher = check.value(QStringLiteral("launcher")).toString();
    const QString relative = launcher.startsWith(m_paths->runtimeDir() + QLatin1Char('/'))
            ? launcher.mid(m_paths->runtimeDir().size() + 1)
            : launcher;

    bool envOk = false;
    const QProcessEnvironment environment = cliEnvironment(&envOk);
    if (!envOk) {
        return nullptr;
    }

    TaskSpec spec;
    spec.kind = QStringLiteral("game");
    spec.label = label.isEmpty() ? slug : label;
    spec.program = QStringLiteral("bash");
    spec.arguments = {m_paths->runtimeDir() + QLatin1Char('/') + relative};
    spec.workingDirectory = m_paths->runtimeDir();
    spec.environment = environment;
    spec.timeoutMs = 0;
    spec.probe = false;
    spec.detail = slug;

    Task *task = m_tasks->run(spec);
    connect(m_tasks, &TaskManager::taskFinished, task, [this, task](Task *finished) {
        if (finished == task
            && (task->state() == Task::State::Failed
                || task->state() == Task::State::TimedOut)) {
            setLastError(task->errorSummary());
        }
    });
    return task;
}

void HypsAdapter::setLastError(const QString &message)
{
    if (m_lastError == message) {
        return;
    }
    m_lastError = message;
    emit lastErrorChanged();
}

} // namespace hyps
