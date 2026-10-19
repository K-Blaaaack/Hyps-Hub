#include <QtTest>
#include <QTemporaryDir>

#include "adapter/environmentreport.h"
#include "app/apppaths.h"
#include "app/appsettings.h"
#include "app/taskmanager.h"
#include "diagnostics/diagnostics.h"
#include "runtime/runtimemanager.h"
#include "version.h"

using namespace hyps;

class TestDiagnostics : public QObject
{
    Q_OBJECT

private slots:
    void exportsRedactedBundle();
    void exportsOnlyTailOfLargeTaskLog();
};

void TestDiagnostics::exportsRedactedBundle()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));

    AppPaths paths(env);
    RuntimeManager runtime(&paths);
    EnvironmentReport report;
    report.parse(QStringLiteral("[Hyps] 环境检测\n\n系统\n  [✓] 内核   Linux\n\n"
                                "必需项: 1/1 通过\n"));
    TaskManager tasks(&paths);
    AppSettings settings(paths.guiConfigFile());
    settings.load();

    // 伪造任务日志与历史，包含疑似密钥
    QDir().mkpath(paths.tasksLogDir());
    const QString logPath = paths.tasksLogDir() + QStringLiteral("/test.log");
    {
        QFile log(logPath);
        QVERIFY(log.open(QIODevice::WriteOnly | QIODevice::Text));
        log.write("# Hyps Hub 任务日志\n[out] hello\n"
                  "[err] TOKEN=supersecret-value\n"
                  "[err] Authorization: Bearer bearer-secret\n"
                  "[err] --token cli-token-secret\n"
                  "[err] api_key: \"quoted secret value\"\n"
                  "[err] https://bob:url-pass@example.invalid/repo\n");
    }
    {
        QFile history(paths.taskHistoryFile());
        QVERIFY(history.open(QIODevice::WriteOnly | QIODevice::Text));
        history.write("{\"id\":\"x\",\"label\":\"test\",\"password\":\"hunter2\"}\n");
    }
    {
        QFile runtimeLog(paths.runtimeLogFile());
        QVERIFY(runtimeLog.open(QIODevice::WriteOnly | QIODevice::Text));
        runtimeLog.write("api_key=abcdef123456\nnormal line\n");
    }

    Diagnostics diagnostics(&paths, &runtime, &report, &tasks, &settings);
    const QVariantMap result = diagnostics.exportBundle(root.filePath(QStringLiteral("export")));
    QVERIFY2(result.value(QStringLiteral("ok")).toBool(),
             qPrintable(result.value(QStringLiteral("error")).toString()));

    const QString bundle = result.value(QStringLiteral("path")).toString();
    QVERIFY(QFile::exists(bundle + QStringLiteral("/summary.txt")));
    QVERIFY(QFile::exists(bundle + QStringLiteral("/README.txt")));
    QVERIFY(QFile::exists(bundle + QStringLiteral("/env-report.txt")));
    QVERIFY(QFile::exists(bundle + QStringLiteral("/logs/runtime.log")));

    QStringList exportedLogs = QDir(bundle + QStringLiteral("/logs/tasks"))
                                       .entryList({QStringLiteral("*.log")}, QDir::Files);
    QCOMPARE(exportedLogs.size(), 1);
    QFile logFile(bundle + QStringLiteral("/logs/tasks/") + exportedLogs.first());
    QVERIFY(logFile.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString logText = QString::fromUtf8(logFile.readAll());
    QVERIFY(logText.contains(QStringLiteral("hello")));
    QVERIFY(logText.contains(QStringLiteral("***")));
    QVERIFY(!logText.contains(QStringLiteral("supersecret-value")));
    QVERIFY(!logText.contains(QStringLiteral("bearer-secret")));
    QVERIFY(!logText.contains(QStringLiteral("cli-token-secret")));
    QVERIFY(!logText.contains(QStringLiteral("quoted secret value")));
    QVERIFY(!logText.contains(QStringLiteral("url-pass")));

    QFile runtimeLogFile(bundle + QStringLiteral("/logs/runtime.log"));
    QVERIFY(runtimeLogFile.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString runtimeText = QString::fromUtf8(runtimeLogFile.readAll());
    QVERIFY(!runtimeText.contains(QStringLiteral("abcdef123456")));
    QVERIFY(runtimeText.contains(QStringLiteral("normal line")));

    QFile historyFile(bundle + QStringLiteral("/task-history.jsonl"));
    QVERIFY(historyFile.open(QIODevice::ReadOnly | QIODevice::Text));
    QVERIFY(!QString::fromUtf8(historyFile.readAll()).contains(QStringLiteral("hunter2")));

    QFile summary(bundle + QStringLiteral("/summary.txt"));
    QVERIFY(summary.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString summaryText = QString::fromUtf8(summary.readAll());
    QVERIFY(summaryText.contains(QString::fromLatin1(HYPS_HUB_VERSION)));
    QVERIFY(summaryText.contains(paths.dataDir()));
}

void TestDiagnostics::exportsOnlyTailOfLargeTaskLog()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));

    AppPaths paths(env);
    RuntimeManager runtime(&paths);
    EnvironmentReport report;
    report.parse(QStringLiteral("必需项: 1/1 通过\n"));
    TaskManager tasks(&paths);
    AppSettings settings(paths.guiConfigFile());
    settings.load();

    QDir().mkpath(paths.tasksLogDir());
    QFile log(paths.tasksLogDir() + QStringLiteral("/large.log"));
    QVERIFY(log.open(QIODevice::WriteOnly | QIODevice::Text));
    log.write("[out] START-MARKER\n");
    log.write(QByteArray(1024 * 1024, 'x'));
    log.write("\n[out] END-MARKER\n");
    log.close();

    Diagnostics diagnostics(&paths, &runtime, &report, &tasks, &settings);
    const QVariantMap result = diagnostics.exportBundle(root.filePath(QStringLiteral("export")));
    QVERIFY2(result.value(QStringLiteral("ok")).toBool(),
             qPrintable(result.value(QStringLiteral("error")).toString()));

    const QString bundle = result.value(QStringLiteral("path")).toString();
    QFile exported(bundle + QStringLiteral("/logs/tasks/large.log"));
    QVERIFY(exported.open(QIODevice::ReadOnly | QIODevice::Text));
    const QString text = QString::fromUtf8(exported.readAll());
    QVERIFY(text.contains(QStringLiteral("END-MARKER")));
    QVERIFY(!text.contains(QStringLiteral("START-MARKER")));
}

QTEST_GUILESS_MAIN(TestDiagnostics)

#include "tst_diagnostics.moc"
