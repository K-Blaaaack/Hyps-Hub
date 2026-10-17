#include <QtTest>
#include <QSignalSpy>
#include <QTemporaryDir>

#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

class TestRuntimeManager : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();

    void cloneSuccess();
    void cloneFailureCleansTempDirectory();
    void refusesToOverwriteInvalidTarget();
    void networkCheckWorks();
    void updateRejectedWhenDirty();
    void fastForwardUpdate();
    void failedMergeKeepsRuntimeUsable();

private:
    QProcessEnvironment testEnvironment(const QTemporaryDir &dir) const
    {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), dir.filePath(QStringLiteral("data")));
        env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), dir.filePath(QStringLiteral("config")));
        env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), dir.filePath(QStringLiteral("state")));
        return env;
    }

    QString fakeGit() const
    {
        return QStringLiteral(HYPS_TEST_SOURCE_DIR "/fixtures/fake-git.sh");
    }

    void clearFakeGitEnv()
    {
        for (const char *name : {"FAKE_GIT_CLONE_FAIL", "FAKE_GIT_DIRTY", "FAKE_GIT_BEHIND",
                                 "FAKE_GIT_AHEAD", "FAKE_GIT_MERGE_FAIL"}) {
            qunsetenv(name);
        }
    }
};

void TestRuntimeManager::init()
{
    clearFakeGitEnv();
}

void TestRuntimeManager::cleanup()
{
    clearFakeGitEnv();
}

void TestRuntimeManager::cloneSuccess()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    qputenv("FAKE_GIT_LOG", root.filePath(QStringLiteral("git.log")).toUtf8());

    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    QSignalSpy initialized(&runtime, &RuntimeManager::initialized);
    runtime.startClone();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);

    QCOMPARE(initialized.count(), 1);
    QCOMPARE(runtime.state(), QStringLiteral("ready"));
    QVERIFY(QFile::exists(paths.runtimeDir() + QStringLiteral("/scripts/_Hyps")));
    QVERIFY(QFile::exists(paths.runtimeInfoFile()));
    QCOMPARE(runtime.commitShort(), QStringLiteral("0123456789ab"));
    QCOMPARE(runtime.branch(), QStringLiteral("main"));
    QVERIFY(!runtime.dirty());
    QVERIFY(runtime.progress() > 0.9);

    // 重复初始化不应再次克隆
    runtime.startClone();
    QTest::qWait(300);
    QCOMPARE(runtime.state(), QStringLiteral("ready"));
}

void TestRuntimeManager::cloneFailureCleansTempDirectory()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    qputenv("FAKE_GIT_CLONE_FAIL", "1");
    qputenv("FAKE_GIT_LOG", root.filePath(QStringLiteral("git.log")).toUtf8());

    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.startClone();
    QTRY_COMPARE_WITH_TIMEOUT(runtime.state(), QStringLiteral("error"), 15000);
    QVERIFY(runtime.errorMessage().contains(QStringLiteral("克隆失败")));
    QVERIFY(!QFileInfo::exists(paths.runtimeDir()));

    const QStringList leftovers =
            QDir(paths.runtimeRoot())
                    .entryList({QStringLiteral(".Hyps.clone-*")}, QDir::Dirs | QDir::Hidden);
    QVERIFY2(leftovers.isEmpty(), qPrintable(leftovers.join(QStringLiteral(", "))));
}

void TestRuntimeManager::refusesToOverwriteInvalidTarget()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    AppPaths paths(testEnvironment(root));
    QDir().mkpath(paths.runtimeDir());
    const QString marker = paths.runtimeDir() + QStringLiteral("/user-data.txt");
    {
        QFile file(marker);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("keep me");
    }

    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.startClone();
    QTRY_COMPARE_WITH_TIMEOUT(runtime.state(), QStringLiteral("invalid"), 10000);
    QVERIFY(QFile::exists(marker));
    QVERIFY(runtime.errorMessage().contains(QStringLiteral("未做任何修改")));
}

void TestRuntimeManager::networkCheckWorks()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.checkNetwork();
    QTRY_COMPARE_WITH_TIMEOUT(runtime.networkStatus(), QStringLiteral("ok"), 15000);
    QVERIFY(runtime.networkDetail().contains(QStringLiteral("0123456789ab")));
}

void TestRuntimeManager::updateRejectedWhenDirty()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    const QString gitLog = root.filePath(QStringLiteral("git.log"));
    qputenv("FAKE_GIT_LOG", gitLog.toUtf8());
    qputenv("FAKE_GIT_BEHIND", "2");

    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.startClone();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);

    qputenv("FAKE_GIT_DIRTY", "1");
    runtime.checkForUpdates();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.updateAvailable(), 15000);
    QVERIFY(runtime.dirty());
    QVERIFY(runtime.updateStatusText().contains(QStringLiteral("更新会被阻止")));

    runtime.applyUpdate();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.updateStatusText().contains(QStringLiteral("已停止更新")),
                             10000);
    QCOMPARE(runtime.state(), QStringLiteral("ready"));
    QVERIFY(!QFile::exists(paths.updateHistoryFile()));

    QFile log(gitLog);
    QVERIFY(log.open(QIODevice::ReadOnly | QIODevice::Text));
    QVERIFY(!QString::fromUtf8(log.readAll()).contains(QStringLiteral("merge --ff-only")));
}

void TestRuntimeManager::fastForwardUpdate()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    qputenv("FAKE_GIT_LOG", root.filePath(QStringLiteral("git.log")).toUtf8());
    qputenv("FAKE_GIT_BEHIND", "1");

    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.startClone();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);

    runtime.checkForUpdates();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.updateAvailable(), 15000);
    QCOMPARE(runtime.behindCount(), 1);

    QSignalSpy finished(&runtime, &RuntimeManager::updateFinished);
    runtime.applyUpdate();
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 15000);
    QVERIFY(finished.at(0).at(0).toBool());
    QCOMPARE(runtime.state(), QStringLiteral("ready"));
    QVERIFY(!runtime.updateAvailable());
    QVERIFY(runtime.updateStatusText().contains(QStringLiteral("已更新到")));
    QVERIFY(QFile::exists(paths.updateHistoryFile()));
}

void TestRuntimeManager::failedMergeKeepsRuntimeUsable()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());
    qputenv("FAKE_GIT_LOG", root.filePath(QStringLiteral("git.log")).toUtf8());
    qputenv("FAKE_GIT_BEHIND", "1");
    qputenv("FAKE_GIT_MERGE_FAIL", "1");

    AppPaths paths(testEnvironment(root));
    RuntimeManager runtime(&paths);
    runtime.setGitProgramForTesting(fakeGit());
    runtime.setRepositoryUrlForTesting(QStringLiteral("https://example.invalid/Hyps.git"));

    runtime.startClone();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.ready(), 15000);
    runtime.checkForUpdates();
    QTRY_VERIFY_WITH_TIMEOUT(runtime.updateAvailable(), 15000);

    QSignalSpy finished(&runtime, &RuntimeManager::updateFinished);
    runtime.applyUpdate();
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 15000);
    QVERIFY(!finished.at(0).at(0).toBool());
    QCOMPARE(runtime.state(), QStringLiteral("ready"));
    QVERIFY(runtime.updateStatusText().contains(QStringLiteral("更新失败")));
    QVERIFY(QFile::exists(paths.runtimeDir() + QStringLiteral("/scripts/_Hyps")));
}

QTEST_GUILESS_MAIN(TestRuntimeManager)

#include "tst_runtimemanager.moc"
