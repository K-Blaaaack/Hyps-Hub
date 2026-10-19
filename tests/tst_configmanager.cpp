#include <QtTest>
#include <QTemporaryDir>

#include "adapter/configfile.h"
#include "adapter/configmanager.h"
#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

class TestConfigManager : public QObject
{
    Q_OBJECT

private slots:
    void acceptsHyphenatedGameSlug();
    void reportsUnsavedChanges();
};

void TestConfigManager::acceptsHyphenatedGameSlug()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));
    AppPaths paths(env);
    RuntimeManager runtime(&paths);
    ConfigManager configs(&paths, &runtime);

    QDir().mkpath(configs.gamesDirectory());
    QFile file(configs.gamesDirectory() + QStringLiteral("/my-game.conf"));
    QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
    file.write("game.exe = \"/tmp/my-game.exe\"\n");
    file.close();

    ConfigFile *config = configs.gameConfig(QStringLiteral("my-game"));
    QVERIFY(config != nullptr);
    QVERIFY(config->exists());
    QCOMPARE(config->valueFor(QStringLiteral("game.exe")),
             QStringLiteral("/tmp/my-game.exe"));

    // 带路径分隔符的 slug 仍必须拒绝。
    QVERIFY(configs.gameConfig(QStringLiteral("../escape")) == nullptr);
}

void TestConfigManager::reportsUnsavedChanges()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));
    AppPaths paths(env);
    RuntimeManager runtime(&paths);
    ConfigManager configs(&paths, &runtime);

    QDir().mkpath(configs.gamesDirectory());
    QFile file(configs.gamesDirectory() + QStringLiteral("/starrail.conf"));
    QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
    file.write("game.exe = \"/tmp/starrail.exe\"\n");
    file.close();

    QVERIFY(!configs.hasUnsavedChanges());
    ConfigFile *config = configs.gameConfig(QStringLiteral("starrail"));
    QVERIFY(config != nullptr);
    QVERIFY(config->setValue(QStringLiteral("game.exe"), QStringLiteral("/tmp/other.exe")));
    QVERIFY(configs.hasUnsavedChanges());

    // 未保存的新配置不能因为 load 而清零 dirty。
    QVERIFY(config->dirty());
}

QTEST_GUILESS_MAIN(TestConfigManager)

#include "tst_configmanager.moc"
