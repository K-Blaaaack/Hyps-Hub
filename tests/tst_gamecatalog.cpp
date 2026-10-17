#include <QtTest>
#include <QTemporaryDir>

#include "adapter/gamecatalog.h"
#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

class TestGameCatalog : public QObject
{
    Q_OBJECT

private slots:
    void listsConfiguredGamesAndTemplates();
    void detectsMissingExeAndLauncher();

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
};

void TestGameCatalog::listsConfiguredGamesAndTemplates()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));

    AppPaths paths(env);
    RuntimeManager runtime(&paths);

    // Hyps 组件结构 + 一个启动脚本 + 示例模板
    const QString runtimeDir = paths.runtimeDir();
    QDir().mkpath(runtimeDir + QStringLiteral("/config/games.examples"));
    QDir().mkpath(runtimeDir + QStringLiteral("/scripts"));
    writeFile(runtimeDir + QStringLiteral("/config.conf"), "path.config = \"./config\"\n");
    writeFile(runtimeDir + QStringLiteral("/init.sh"), "#!/usr/bin/env bash\n");
    writeFile(runtimeDir + QStringLiteral("/lib/libs.sh"), "\n");
    writeFile(runtimeDir + QStringLiteral("/lib/common.sh"), "\n");
    writeFile(runtimeDir + QStringLiteral("/scripts/_Hyps"), "#!/usr/bin/env bash\n", true);
    writeFile(runtimeDir + QStringLiteral("/config/games.examples/starrail.example.conf"),
              "game.exe = \"/path/to/Star Rail Game/StarRail.exe\"\n");
    writeFile(runtimeDir + QStringLiteral("/scripts/StarRail.sh"),
              "#!/usr/bin/env bash\nGAME_NAME=\"starrail\"\n", true);

    const QString gameExe = root.filePath(QStringLiteral("StarRail.exe"));
    writeFile(gameExe, "binary\n", true);

    writeFile(paths.hypsConfigDir() + QStringLiteral("/runners/umu-dwproton.conf"),
              "runner.exe = \"umu-run\"\nrunner.protonpath = \"dwproton\"\n");
    writeFile(paths.hypsConfigDir() + QStringLiteral("/games/starrail.conf"),
              QStringLiteral("game.exe = \"%1\"\nrunner.name = \"umu-dwproton\"\n")
                      .arg(gameExe)
                      .toUtf8());

    GameCatalog catalog(&paths, &runtime);
    QCOMPARE(catalog.count(), 1);

    const QVariantMap game = catalog.gameBySlug(QStringLiteral("starrail"));
    QCOMPARE(game.value(QStringLiteral("label")).toString(),
             QStringLiteral("崩坏：星穹铁道"));
    QCOMPARE(game.value(QStringLiteral("status")).toString(), QStringLiteral("就绪"));
    QVERIFY(game.value(QStringLiteral("launchable")).toBool());
    QVERIFY(game.value(QStringLiteral("exeExists")).toBool());
    QCOMPARE(game.value(QStringLiteral("launcherPath")).toString(),
             runtimeDir + QStringLiteral("/scripts/StarRail.sh"));
    QCOMPARE(catalog.firstSlug(), QStringLiteral("starrail"));

    const QVariantList templates = catalog.templates();
    QCOMPARE(templates.size(), 1);
    QVERIFY(templates.first().toMap().value(QStringLiteral("configured")).toBool());
}

void TestGameCatalog::detectsMissingExeAndLauncher()
{
    QTemporaryDir root;
    QVERIFY(root.isValid());

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
    env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
    env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));

    AppPaths paths(env);
    RuntimeManager runtime(&paths);
    QDir().mkpath(paths.runtimeDir() + QStringLiteral("/scripts"));
    QDir().mkpath(paths.runtimeDir() + QStringLiteral("/config/games.examples"));
    writeFile(paths.runtimeDir() + QStringLiteral("/config.conf"), "\n");
    writeFile(paths.runtimeDir() + QStringLiteral("/init.sh"), "\n");
    writeFile(paths.runtimeDir() + QStringLiteral("/lib/libs.sh"), "\n");
    writeFile(paths.runtimeDir() + QStringLiteral("/lib/common.sh"), "\n");
    writeFile(paths.runtimeDir() + QStringLiteral("/scripts/_Hyps"), "\n");

    // game.exe 不存在
    writeFile(paths.hypsConfigDir() + QStringLiteral("/games/starrail.conf"),
              "game.exe = \"/nonexistent/game.exe\"\nrunner.name = \"umu-dwproton\"\n");
    writeFile(paths.hypsConfigDir() + QStringLiteral("/runners/umu-dwproton.conf"),
              "runner.exe = \"umu-run\"\n");
    writeFile(paths.runtimeDir() + QStringLiteral("/scripts/StarRail.sh"),
              "GAME_NAME=\"starrail\"\n");

    GameCatalog catalog(&paths, &runtime);
    QVariantMap game = catalog.gameBySlug(QStringLiteral("starrail"));
    QCOMPARE(game.value(QStringLiteral("status")).toString(),
             QStringLiteral("game.exe 不存在"));
    QVERIFY(!game.value(QStringLiteral("launchable")).toBool());

    // 有配置但无启动脚本
    writeFile(paths.hypsConfigDir() + QStringLiteral("/games/wuwa.conf"),
              "game.exe = \"/nonexistent/wuwa.exe\"\nrunner.name = \"umu-dwproton\"\n");
    catalog.refresh();
    game = catalog.gameBySlug(QStringLiteral("wuwa"));
    QCOMPARE(game.value(QStringLiteral("status")).toString(),
             QStringLiteral("缺少启动脚本"));
    QCOMPARE(game.value(QStringLiteral("statusLevel")).toString(),
             QStringLiteral("error"));
}

QTEST_GUILESS_MAIN(TestGameCatalog)

#include "tst_gamecatalog.moc"
