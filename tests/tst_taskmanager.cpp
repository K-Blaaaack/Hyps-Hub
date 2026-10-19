#include <QtTest>
#include <QTemporaryDir>

#include "app/apppaths.h"
#include "app/logmodel.h"
#include "app/task.h"
#include "app/taskmanager.h"

#include <QDateTime>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

using namespace hyps;

class TestTaskManager : public QObject
{
    Q_OBJECT

private slots:
    void lazyLoadsTailOfLargeLog();
    void clearingHistoryRemovesTaskLog();
};

void TestTaskManager::lazyLoadsTailOfLargeLog()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));
    AppPaths paths(env);
    QDir().mkpath(paths.stateDir());
    QDir().mkpath(paths.tasksLogDir());

    const QString logPath = paths.tasksLogDir() + QStringLiteral("/large.log");
    {
        QFile log(logPath);
        QVERIFY(log.open(QIODevice::WriteOnly | QIODevice::Text));
        log.write("[out] START-MARKER\n");
        log.write(QByteArray(3 * 1024 * 1024, 'x'));
        log.write("\n[out] END-MARKER\n");
    }

    const QDateTime now = QDateTime::currentDateTime();
    QJsonObject object;
    object.insert(QStringLiteral("id"), QStringLiteral("abc12345"));
    object.insert(QStringLiteral("kind"), QStringLiteral("game"));
    object.insert(QStringLiteral("label"), QStringLiteral("large log"));
    object.insert(QStringLiteral("state"), QStringLiteral("succeeded"));
    object.insert(QStringLiteral("startedAt"), now.addSecs(-10).toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("finishedAt"), now.toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("exitCode"), 0);
    object.insert(QStringLiteral("hasExitCode"), true);
    object.insert(QStringLiteral("logPath"), logPath);
    {
        QFile history(paths.taskHistoryFile());
        QVERIFY(history.open(QIODevice::WriteOnly | QIODevice::Text));
        history.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
        history.write("\n");
    }

    TaskManager tasks(&paths);
    QVERIFY(tasks.currentTask() != nullptr);
    // 历史任务在构造/启动阶段不应同步读取大日志。
    QCOMPARE(tasks.currentTask()->log()->totalCount(), 0);

    tasks.loadCurrentLog();
    QVERIFY(tasks.currentTask()->log()->totalCount() > 0);
    const QString text = tasks.currentTask()->log()->fullText();
    QVERIFY(text.contains(QStringLiteral("END-MARKER")));
    QVERIFY(!text.contains(QStringLiteral("START-MARKER")));
}

void TestTaskManager::clearingHistoryRemovesTaskLog()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));
    AppPaths paths(env);
    QDir().mkpath(paths.stateDir());
    QDir().mkpath(paths.tasksLogDir());

    const QString logPath = paths.tasksLogDir() + QStringLiteral("/old.log");
    {
        QFile log(logPath);
        QVERIFY(log.open(QIODevice::WriteOnly | QIODevice::Text));
        log.write("[out] old\n");
    }

    const QDateTime now = QDateTime::currentDateTime();
    QJsonObject object;
    object.insert(QStringLiteral("id"), QStringLiteral("old12345"));
    object.insert(QStringLiteral("kind"), QStringLiteral("diagnostics"));
    object.insert(QStringLiteral("label"), QStringLiteral("old"));
    object.insert(QStringLiteral("state"), QStringLiteral("succeeded"));
    object.insert(QStringLiteral("startedAt"), now.addSecs(-5).toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("finishedAt"), now.toString(Qt::ISODateWithMs));
    object.insert(QStringLiteral("exitCode"), 0);
    object.insert(QStringLiteral("hasExitCode"), true);
    object.insert(QStringLiteral("logPath"), logPath);
    {
        QFile history(paths.taskHistoryFile());
        QVERIFY(history.open(QIODevice::WriteOnly | QIODevice::Text));
        history.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
        history.write("\n");
    }

    TaskManager tasks(&paths);
    QVERIFY(QFile::exists(logPath));
    tasks.clearFinishedHistory();
    QVERIFY(!QFile::exists(logPath));
}

QTEST_GUILESS_MAIN(TestTaskManager)

#include "tst_taskmanager.moc"
