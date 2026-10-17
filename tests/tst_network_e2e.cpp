#include <QtTest>
#include <QElapsedTimer>
#include <QTemporaryDir>

#include "adapter/environmentreport.h"
#include "adapter/hypsadapter.h"
#include "app/apppaths.h"
#include "app/task.h"
#include "app/taskmanager.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

/*
 * 真实网络端到端测试：克隆上游仓库 → 初始化隔离配置 → 运行 init.sh --check →
 * 验证 scripts/_Hyps --help。默认禁用（CTest 中 DISABLED）。
 *
 * 手动运行：
 *   HYPS_HUB_RUN_NETWORK_TESTS=1 TMPDIR=$PWD/build/tests/tmp \
 *     ./build/tests/tst_network_e2e
 */
class TestNetworkE2E : public QObject
{
    Q_OBJECT

private slots:
    void cloneInitializeAndCheck();

private:
    bool waitForTask(Task *task, int timeoutMs = 120000)
    {
        if (!task) {
            return false;
        }
        QElapsedTimer timer;
        timer.start();
        while (task->active() && timer.elapsed() < timeoutMs) {
            QTest::qWait(100);
        }
        return !task->active();
    }
};

void TestNetworkE2E::cloneInitializeAndCheck()
{
    if (qEnvironmentVariable("HYPS_HUB_RUN_NETWORK_TESTS") != QLatin1String("1")) {
        QSKIP("设置 HYPS_HUB_RUN_NETWORK_TESTS=1 以运行真实网络测试");
    }

    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));

    AppPaths paths(env);
    QVERIFY(paths.runtimeDir().startsWith(paths.dataDir()));
    QVERIFY(!paths.runtimeDir().contains(QStringLiteral("/home/kb/Hyps/")));

    RuntimeManager runtime(&paths);
    QSignalSpy initialized(&runtime, &RuntimeManager::initialized);
    runtime.startClone();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 300000);
    if (!runtime.ready()) {
        qWarning() << "clone error:" << runtime.errorMessage();
        QFAIL("真实克隆失败");
    }
    QCOMPARE(initialized.count(), 1);
    QVERIFY(!runtime.commit().isEmpty());
    QVERIFY(QFile::exists(paths.runtimeDir() + QStringLiteral("/scripts/_Hyps")));
    qInfo() << "runtime:" << paths.runtimeDir() << "commit:" << runtime.commitShort()
            << runtime.commitSubject();

    TaskManager tasks(&paths);
    EnvironmentReport report;
    HypsAdapter adapter(&paths, &runtime, &tasks, &report);

    Task *initTask = adapter.initializeConfig();
    QVERIFY(initTask);
    QVERIFY(waitForTask(initTask, 120000));
    QCOMPARE(initTask->state(), Task::State::Succeeded);
    QVERIFY(QFile::exists(paths.hypsConfigDir() + QStringLiteral("/games/_common.conf")));
    // 隔离：配置写入 CONFIG_DIR，不进入运行副本工作区
    QVERIFY(!QFile::exists(paths.runtimeDir() + QStringLiteral("/config/games/_common.conf")));

    Task *checkTask = adapter.checkEnvironment();
    QVERIFY(checkTask);
    QVERIFY(waitForTask(checkTask, 120000));
    QTRY_VERIFY_WITH_TIMEOUT(report.hasReport(), 10000);
    QVERIFY(report.requiredTotal() > 0);
    qInfo() << "environment:" << report.summaryText();
    if (report.requiredFailed() > 0) {
        qWarning() << "缺失必需项：" << report.requiredFailed();
    }

    Task *cliTask = adapter.verifyCli();
    QVERIFY(cliTask);
    QVERIFY(waitForTask(cliTask, 60000));
    QCOMPARE(cliTask->state(), Task::State::Succeeded);
    QVERIFY(adapter.cliVerified());
    QVERIFY(cliTask->capturedStdout().contains(QStringLiteral("game")));

    QFile infoFile(paths.runtimeInfoFile());
    QVERIFY(infoFile.open(QIODevice::ReadOnly | QIODevice::Text));
    QVERIFY(QString::fromUtf8(infoFile.readAll()).contains(QStringLiteral("initializedAt")));
}

QTEST_GUILESS_MAIN(TestNetworkE2E)

#include "tst_network_e2e.moc"
