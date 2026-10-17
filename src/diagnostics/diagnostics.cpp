#include "diagnostics/diagnostics.h"

#include "adapter/environmentreport.h"
#include "app/apppaths.h"
#include "app/appsettings.h"
#include "app/taskmanager.h"
#include "runtime/runtimemanager.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>

namespace hyps {

Diagnostics::Diagnostics(AppPaths *paths, RuntimeManager *runtime, EnvironmentReport *report,
                         TaskManager *tasks, AppSettings *settings, QObject *parent)
    : QObject(parent)
    , m_paths(paths)
    , m_runtime(runtime)
    , m_report(report)
    , m_tasks(tasks)
    , m_settings(settings)
{
}

QString Diagnostics::defaultExportDirectory() const
{
    const QString documents =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!documents.isEmpty() && QFileInfo(documents).isDir()) {
        return documents;
    }
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    return home.isEmpty() ? m_paths->dataDir() : home;
}

QString Diagnostics::redact(const QString &text) const
{
    static const QRegularExpression secretRe(
            QStringLiteral("(token|password|passwd|secret|api[_-]?key|authorization|auth)"
                           "([\\s\"']*[:=][\\s\"']*)([^\\s\"',]+)"),
            QRegularExpression::CaseInsensitiveOption);
    QString result = text;
    result.replace(secretRe, QStringLiteral("\\1\\2***"));
    return result;
}

QString Diagnostics::tailOfFile(const QString &path, int maxLines) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }
    const QByteArray content = file.read(8 * 1024 * 1024);
    const QStringList lines = QString::fromUtf8(content).split(QLatin1Char('\n'));
    const int start = qMax(0, static_cast<int>(lines.size()) - maxLines);
    return lines.mid(start).join(QLatin1Char('\n'));
}

bool Diagnostics::writeTextFile(const QString &directory, const QString &name,
                                const QString &content, QString *error) const
{
    const QString path = directory + QLatin1Char('/') + name;
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        if (error) {
            *error = tr("无法写入 %1：%2").arg(path, file.errorString());
        }
        return false;
    }
    file.write(content.toUtf8());
    return true;
}

QString Diagnostics::buildSummary() const
{
    QStringList lines;
    lines << QStringLiteral("Hyps Hub 诊断摘要")
          << QStringLiteral("==================")
          << QStringLiteral("生成时间: %1").arg(QDateTime::currentDateTime().toString(Qt::ISODate))
          << QStringLiteral("应用版本: %1 (%2)").arg(m_paths->appVersion(), m_paths->gitCommit())
          << QStringLiteral("Qt: %1").arg(m_paths->qtVersion())
          << QStringLiteral("系统: %1").arg(m_paths->osPrettyName())
          << QStringLiteral("内核: %1").arg(m_paths->kernelVersion())
          << QStringLiteral("会话: %1 / %2").arg(m_paths->sessionType(), m_paths->desktopName())
          << QStringLiteral("Wayland: %1").arg(m_paths->wayland() ? QStringLiteral("是")
                                                                  : QStringLiteral("否"))
          << QStringLiteral("以 root 运行: %1").arg(m_paths->runningAsRoot() ? QStringLiteral("是")
                                                                           : QStringLiteral("否"))
          << QString()
          << QStringLiteral("路径")
          << QStringLiteral("----");
    for (const QVariant &entry : m_paths->directories()) {
        const QVariantMap map = entry.toMap();
        lines << QStringLiteral("%1: %2  (%3)")
                         .arg(map.value(QStringLiteral("name")).toString(),
                              map.value(QStringLiteral("path")).toString(),
                              map.value(QStringLiteral("description")).toString());
    }

    lines << QString()
          << QStringLiteral("Hyps 组件")
          << QStringLiteral("--------")
          << QStringLiteral("状态: %1").arg(m_runtime->state())
          << QStringLiteral("提交: %1 %2")
                     .arg(m_runtime->commitShort(), m_runtime->commitSubject())
          << QStringLiteral("分支: %1").arg(m_runtime->branch())
          << QStringLiteral("未提交修改: %1").arg(m_runtime->dirty() ? QStringLiteral("是")
                                                                     : QStringLiteral("否"))
          << QStringLiteral("上游更新: %1").arg(m_runtime->updateStatusText())
          << QStringLiteral("落后/领先: %1 / %2")
                     .arg(m_runtime->behindCount())
                     .arg(m_runtime->aheadCount())
          << QStringLiteral("CLI 入口: %1 (%2)")
                     .arg(m_paths->cliEntryPoint(),
                          QFileInfo(m_paths->cliEntryPoint()).isReadable()
                                  ? QStringLiteral("可读")
                                  : QStringLiteral("不可读"));

    lines << QString()
          << QStringLiteral("环境检测")
          << QStringLiteral("--------")
          << QStringLiteral("时间: %1").arg(m_report->checkedAtText())
          << QStringLiteral("结果: %1").arg(m_report->summaryText());

    lines << QString()
          << QStringLiteral("GUI 前置检查")
          << QStringLiteral("-------------");
    for (const QVariant &item : m_runtime->prerequisites()) {
        const QVariantMap map = item.toMap();
        lines << QStringLiteral("[%1] %2: %3")
                         .arg(map.value(QStringLiteral("ok")).toBool() ? QStringLiteral("✓")
                                                                      : QStringLiteral("✗"),
                              map.value(QStringLiteral("name")).toString(),
                              map.value(QStringLiteral("detail")).toString());
    }

    lines << QString()
          << QStringLiteral("说明")
          << QStringLiteral("----")
          << QStringLiteral("本包不包含 Hyps 组件、游戏文件或 GUI 配置中的敏感值。")
          << QStringLiteral("任务命令与输出仅保留最近部分，疑似密钥字段已替换为 ***。");

    return lines.join(QLatin1Char('\n'));
}

QVariantMap Diagnostics::exportBundle(const QString &targetDirectory)
{
    m_lastExportPath.clear();
    m_lastExportError.clear();
    emit exportStateChanged();

    QString target = targetDirectory.trimmed();
    if (target.startsWith(QLatin1String("file://"))) {
        target = QUrl(target).toLocalFile();
    }
    if (target.isEmpty()) {
        target = defaultExportDirectory();
    }

    QVariantMap result;
    if (!QDir().mkpath(target)) {
        m_lastExportError = tr("无法创建导出目录：%1").arg(target);
        emit exportStateChanged();
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), m_lastExportError);
        return result;
    }

    const QString stamp =
            QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    QString bundle = target + QStringLiteral("/hyps-hub-diagnostics-") + stamp;
    int suffix = 1;
    while (QFileInfo::exists(bundle)) {
        bundle = target + QStringLiteral("/hyps-hub-diagnostics-") + stamp
                + QStringLiteral("-") + QString::number(suffix++);
    }

    QString error;
    if (!QDir().mkpath(bundle) || !QDir().mkpath(bundle + QStringLiteral("/logs/tasks"))) {
        m_lastExportError = tr("无法创建诊断目录：%1").arg(bundle);
        emit exportStateChanged();
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), m_lastExportError);
        return result;
    }

    int files = 0;
    auto write = [&](const QString &name, const QString &content) {
        if (writeTextFile(bundle, name, redact(content), &error)) {
            ++files;
        }
    };

    write(QStringLiteral("summary.txt"), buildSummary());
    write(QStringLiteral("env-report.txt"), m_report->rawText());
    write(QStringLiteral("env-report.json"), [&]() {
        QFile file(m_paths->envReportFile());
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return QString();
        }
        return QString::fromUtf8(file.readAll());
    }());

    write(QStringLiteral("runtime-info.json"), [&]() {
        QFile file(m_paths->runtimeInfoFile());
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return QString();
        }
        return QString::fromUtf8(file.readAll());
    }());

    if (m_settings) {
        QFile file(m_settings->filePath());
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            write(QStringLiteral("gui-config.json"), QString::fromUtf8(file.readAll()));
        }
    }

    const QString history = tailOfFile(m_paths->taskHistoryFile(), 50);
    if (!history.isEmpty()) {
        write(QStringLiteral("task-history.jsonl"), history);
    }

    const QString runtimeLog = tailOfFile(m_paths->runtimeLogFile(), 500);
    if (!runtimeLog.isEmpty()) {
        write(QStringLiteral("logs/runtime.log"), runtimeLog);
    }

    const QDir taskLogs(m_paths->tasksLogDir());
    QFileInfoList logFiles = taskLogs.entryInfoList({QStringLiteral("*.log")}, QDir::Files,
                                                    QDir::Time);
    logFiles = logFiles.mid(0, 10);
    for (const QFileInfo &logFile : logFiles) {
        write(QStringLiteral("logs/tasks/") + logFile.fileName(),
              tailOfFile(logFile.absoluteFilePath(), 2000));
    }

    const QString readme = QStringLiteral(
            "Hyps Hub 诊断包\n"
            "================\n\n"
            "summary.txt            环境、路径、Hyps 组件与依赖摘要\n"
            "env-report.txt/json    最近一次 Hyps 环境检测输出\n"
            "runtime-info.json      Hyps 组件初始化/更新记录\n"
            "gui-config.json        Hyps Hub 自身配置（窗口、主题等）\n"
            "task-history.jsonl     最近任务历史\n"
            "logs/                  应用与任务日志尾部\n\n"
            "隐私说明：本包不包含 Hyps 组件、游戏文件、Proton/umu 环境或用户配置的敏感值；\n"
            "疑似 token/password/secret 的字段已被替换为 ***。请在分享前自行检查内容。\n");
    write(QStringLiteral("README.txt"), readme);

    if (!error.isEmpty()) {
        m_lastExportError = error;
        emit exportStateChanged();
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), error);
        return result;
    }

    m_lastExportPath = bundle;
    emit exportStateChanged();
    result.insert(QStringLiteral("ok"), true);
    result.insert(QStringLiteral("path"), bundle);
    result.insert(QStringLiteral("files"), files);
    return result;
}

} // namespace hyps
