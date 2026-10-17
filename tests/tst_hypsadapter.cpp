#include <QtTest>
#include <QElapsedTimer>
#include <QTemporaryDir>

#include <memory>

#include "adapter/environmentreport.h"
#include "adapter/hypsadapter.h"
#include "app/apppaths.h"
#include "app/task.h"
#include "app/taskmanager.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

class TestHypsAdapter : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void detectsEnvironmentAndInitializesConfig();
    void launchesGameWithIsolatedEnvironment();

private:
    void writeFile(const QString &path, const QByteArray &content, bool executable = false)
    {
        QDir().mkpath(QFileInfo(path).absolutePath());
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Truncate));
        file.write(content);
        file.close();
        if (executable) {
            file.setPermissions(file.permissions() | QFileDevice::ExeOwner
                                | QFileDevice::ExeUser | QFileDevice::ExeGroup);
        }
    }

    bool waitForTask(Task *task, int timeoutMs = 15000)
    {
        if (!task) {
            return false;
        }
        QElapsedTimer timer;
        timer.start();
        while (task->active() && timer.elapsed() < timeoutMs) {
            QTest::qWait(50);
        }
        return !task->active();
    }

    QString fakeGit() const
    {
        return QStringLiteral(HYPS_TEST_SOURCE_DIR "/fixtures/fake-git.sh");
    }

    void createRuntime(const AppPaths &paths)
    {
        const QString runtimeDir = paths.runtimeDir();
        writeFile(runtimeDir + QStringLiteral("/config.conf"), "path.config = \"./config\"\n");
        writeFile(runtimeDir + QStringLiteral("/init.sh"),
                  "#!/usr/bin/env bash\n"
                  "set -e\n"
                  "case \"${1:-}\" in\n"
                  "  --check) cat <<'EOF'\n"
                  "[Hyps] 环境检测\n"
                  "\n"
                  "系统\n"
                  "  [✓] 运行用户   tester\n"
                  "  [✓] 内核       Linux\n"
                  "\n"
                  "必需项: 2/2 通过\n"
                  "EOF\n"
                  "  ;;\n"
                  "  --no-game)\n"
                  "    mkdir -p \"$CONFIG_DIR/games\" \"$CONFIG_DIR/runners\"\n"
                  "    printf 'mangohud.enabled = false\\n' > \"$CONFIG_DIR/games/_common.conf\"\n"
                  "    printf 'runner.exe = \"umu-run\"\\n' > \"$CONFIG_DIR/runners/umu-dwproton.conf\"\n"
                  "    echo init-ok\n"
                  "  ;;\n"
                  "  starrail)\n"
                  "    mkdir -p \"$CONFIG_DIR/games\"\n"
                  "    printf 'game.exe = \"/tmp/fake-game.exe\"\\nrunner.name = \"umu-dwproton\"\\n' > \"$CONFIG_DIR/games/starrail.conf\"\n"
                  "    echo game-ok\n"
                  "  ;;\n"
                  "esac\n",
                  true);
        writeFile(runtimeDir + QStringLiteral("/lib/libs.sh"), "\n");
        writeFile(runtimeDir + QStringLiteral("/lib/common.sh"), "\n");
        writeFile(runtimeDir + QStringLiteral("/scripts/_Hyps"),
                  "#!/usr/bin/env bash\n"
                  "case \"${1:-}\" in\n"
                  "  --help) echo '可用子命令:'; echo '  game'; exit 0 ;;\n"
                  "  game) echo 'game list output'; exit 0 ;;\n"
                  "esac\n"
                  "exit 0\n",
                  true);
        writeFile(runtimeDir + QStringLiteral("/scripts/StarRail.sh"),
                  "#!/usr/bin/env bash\n"
                  "GAME_NAME=\"starrail\"\n"
                  "{\n"
                  "  printf '%s\\n' \"$CONFIG_DIR\"\n"
                  "  printf '%s\\n' \"$CACHE_DIR\"\n"
                  "  printf '%s\\n' \"$DATA_DIR\"\n"
                  "  printf '%s\\n' \"$TEMP_DIR\"\n"
                  "  printf '%s\\n' \"$PWD\"\n"
                  "  printf '%s\\n' \"$NO_COLOR\"\n"
                  "} > \"$HYPS_TEST_MARKER\"\n"
                  "echo game-stdout\n"
                  "exit 0\n",
                  true);
        writeFile(runtimeDir + QStringLiteral("/config/games.examples/starrail.example.conf"),
                  "game.exe = \"/path/to/StarRail.exe\"\n");
    }

    std::unique_ptr<QTemporaryDir> m_root;
    QString m_markerPath;
};

void TestHypsAdapter::init()
{
    m_root = std::make_unique<QTemporaryDir>();
    QVERIFY(m_root->isValid());
    m_markerPath = m_root->filePath(QStringLiteral("marker.txt"));
    qputenv("FAKE_GIT_LOG", m_root->filePath(QStringLiteral("git.log")).toUtf8());
}

void TestHypsAdapter::cleanup()
{
    qunsetenv("FAKE_GIT_LOG");
    qunsetenv("HYPS_TEST_MARKER");
}

void TestHypsAdapter::detectsEnvironmentAndInitializesConfig()
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), m_root->filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), m_root->filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), m_root->filePath(QStringLiteral("state")));
    env.insert(QStringLiteral("HYPS_TEST_MARKER"), m_markerPath);

    AppPaths paths(env);
    TaskManager tasks(&paths);
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));
    EnvironmentReport report;
    HypsAdapter adapter(&paths, &runtime, &tasks, &report);

    createRuntime(paths);
    runtime.refresh();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);

    Task *initTask = adapter.initializeConfig();
    QVERIFY(initTask);
    QVERIFY(waitForTask(initTask));
    QCOMPARE(initTask->state(), Task::State::Succeeded);
    QVERIFY(QFile::exists(paths.hypsConfigDir() + QStringLiteral("/games/_common.conf")));
    QVERIFY(QFile::exists(paths.hypsConfigDir() + QStringLiteral("/runners/umu-dwproton.conf")));
    QVERIFY(!QFile::exists(paths.runtimeDir()
                           + QStringLiteral("/config/games/_common.conf")));

    Task *createTask = adapter.createGameConfig(QStringLiteral("starrail"));
    QVERIFY(createTask);
    QVERIFY(waitForTask(createTask));
    QCOMPARE(createTask->state(), Task::State::Succeeded);
    QVERIFY(QFile::exists(paths.hypsConfigDir() + QStringLiteral("/games/starrail.conf")));

    Task *checkTask = adapter.checkEnvironment();
    QVERIFY(checkTask);
    QVERIFY(waitForTask(checkTask));
    QTRY_VERIFY_WITH_TIMEOUT(report.hasReport(), 5000);
    QCOMPARE(report.requiredTotal(), 2);
    QCOMPARE(report.requiredPassed(), 2);
    QVERIFY(QFile::exists(paths.envReportFile()));

    QVERIFY(adapter.canRun());
    QVERIFY(adapter.canLaunch(QStringLiteral("starrail")).value(QStringLiteral("ok")).toBool());

    Task *diagnostic = adapter.runDiagnostic(QStringLiteral("game-list"));
    QVERIFY(diagnostic);
    QVERIFY(waitForTask(diagnostic));
    QCOMPARE(diagnostic->state(), Task::State::Succeeded);
    QVERIFY(diagnostic->capturedStdout().contains(QStringLiteral("game list output")));

    QVERIFY(adapter.runDiagnostic(QStringLiteral("evil")) == nullptr);
    QVERIFY(adapter.lastError().contains(QStringLiteral("未授权")));
}

void TestHypsAdapter::launchesGameWithIsolatedEnvironment()
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), m_root->filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), m_root->filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), m_root->filePath(QStringLiteral("state")));
    env.insert(QStringLiteral("HYPS_TEST_MARKER"), m_markerPath);

    AppPaths paths(env);
    TaskManager tasks(&paths);
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));
    EnvironmentReport report;
    HypsAdapter adapter(&paths, &runtime, &tasks, &report);

    createRuntime(paths);
    writeFile(paths.hypsConfigDir() + QStringLiteral("/games/starrail.conf"),
              "game.exe = \"/tmp/fake-game.exe\"\nrunner.name = \"umu-dwproton\"\n");
    writeFile(paths.hypsConfigDir() + QStringLiteral("/runners/umu-dwproton.conf"),
              "runner.exe = \"umu-run\"\n");
    runtime.refresh();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);

    Task *task = adapter.launchGame(QStringLiteral("starrail"), QStringLiteral("崩坏：星穹铁道"));
    QVERIFY(task);
    QVERIFY(waitForTask(task));
    QCOMPARE(task->state(), Task::State::Succeeded);
    QVERIFY(task->capturedStdout().contains(QStringLiteral("game-stdout")));

    QVERIFY(QFile::exists(m_markerPath));
    QFile marker(m_markerPath);
    QVERIFY(marker.open(QIODevice::ReadOnly | QIODevice::Text));
    const QStringList lines = QString::fromUtf8(marker.readAll()).split(QLatin1Char('\n'),
                                                                       Qt::SkipEmptyParts);
    QVERIFY(lines.size() >= 6);
    QCOMPARE(lines.at(0), paths.hypsConfigDir());
    QCOMPARE(lines.at(1), paths.hypsCacheDir());
    QCOMPARE(lines.at(2), paths.hypsDataDir());
    QCOMPARE(lines.at(3), paths.hypsTempDir());
    QCOMPARE(QFileInfo(lines.at(4)).canonicalFilePath(),
             QFileInfo(paths.runtimeDir()).canonicalFilePath());
    QCOMPARE(lines.at(5), QStringLiteral("1"));

    // 未配置的游戏不能启动
    QVERIFY(adapter.launchGame(QStringLiteral("wuwa"), QString()) == nullptr);
    QVERIFY(adapter.lastError().contains(QStringLiteral("尚未创建")));
}

QTEST_GUILESS_MAIN(TestHypsAdapter)

#include "tst_hypsadapter.moc"
