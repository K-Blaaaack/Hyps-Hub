#include <QtTest>
#include <QTemporaryDir>

#include <memory>

#include "adapter/configfile.h"
#include "adapter/configmanager.h"
#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

using namespace hyps;

namespace {

/// 每个用例一套隔离的 XDG 根目录，避免污染真实配置。
struct Fixture
{
    QTemporaryDir root;
    std::unique_ptr<AppPaths> paths;
    std::unique_ptr<RuntimeManager> runtime;
    std::unique_ptr<ConfigManager> configs;

    Fixture()
    {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), root.filePath(QStringLiteral("data")));
        env.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), root.filePath(QStringLiteral("config")));
        env.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), root.filePath(QStringLiteral("state")));
        paths = std::make_unique<AppPaths>(env);
        runtime = std::make_unique<RuntimeManager>(paths.get());
        configs = std::make_unique<ConfigManager>(paths.get(), runtime.get());
        QDir().mkpath(configs->gamesDirectory());
    }

    void writeFile(const QString &path, const QString &text)
    {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.write(text.toUtf8());
        file.close();
    }

    void writeGame(const QString &slug, const QString &text)
    {
        writeFile(configs->gamesDirectory() + QLatin1Char('/') + slug
                          + QStringLiteral(".conf"),
                  text);
    }

    void writeCommon(const QString &text) { writeFile(configs->commonConfigPath(), text); }
};

bool hasIssue(const QVariantList &issues, const QString &level, const QString &key)
{
    for (const QVariant &item : issues) {
        const QVariantMap map = item.toMap();
        if (map.value(QStringLiteral("level")).toString() == level
            && map.value(QStringLiteral("key")).toString() == key) {
            return true;
        }
    }
    return false;
}

bool hasError(const QVariantList &issues)
{
    for (const QVariant &item : issues) {
        if (item.toMap().value(QStringLiteral("level")).toString() == QStringLiteral("error")) {
            return true;
        }
    }
    return false;
}

QStringList fieldKeys(const QVariantList &fields)
{
    QStringList keys;
    for (const QVariant &item : fields) {
        keys.append(item.toMap().value(QStringLiteral("key")).toString());
    }
    return keys;
}

QVariantMap fieldByKey(const QVariantList &fields, const QString &key)
{
    for (const QVariant &item : fields) {
        const QVariantMap map = item.toMap();
        if (map.value(QStringLiteral("key")).toString() == key) {
            return map;
        }
    }
    return {};
}

const QStringList endfieldSurrogateKeys = {
    QStringLiteral("endfield.surrogate.mode"),
    QStringLiteral("endfield.surrogate.launcher"),
    QStringLiteral("endfield.surrogate.dir"),
    QStringLiteral("endfield.surrogate.target"),
    QStringLiteral("endfield.surrogate.hardlink_dir"),
    QStringLiteral("endfield.surrogate.hardlink_target"),
    QStringLiteral("endfield.surrogate.copy_dir"),
    QStringLiteral("endfield.surrogate.copy_target"),
    QStringLiteral("endfield.surrogate.keep"),
    QStringLiteral("endfield.surrogate.exit_after"),
    QStringLiteral("endfield.surrogate.show_info"),
};

} // namespace

class TestConfigManager : public QObject
{
    Q_OBJECT

private slots:
    void acceptsHyphenatedGameSlug();
    void reportsUnsavedChanges();

    void commonFieldsDropHostsDisconnect();
    void gameFieldsForEndfieldAppendsSurrogateCatalog();
    void gameFieldsForOtherGamesKeepsBaseCatalog();

    void reportsHostsDisconnectResidualKeys();
    void acceptsCommonWithoutHostsKeys();

    void endfieldSurrogateModeMissing();
    void endfieldSurrogateModeInvalid();
    void endfieldSurrogateDisabledIsClean();
    void endfieldSurrogateDirTargetConflict();
    void endfieldSurrogateHardlinkAndCopyConflicts();
    void endfieldLauncherModeRequiresLauncher();
    void endfieldLauncherModeRejectsSourceKeys();
    void endfieldExitAfterMustBePositiveInteger();
    void endfieldSurrogateKeysIgnoredForOtherGames();

    void warnsAboutRemovedFpsUnlockProg();
};

void TestConfigManager::acceptsHyphenatedGameSlug()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("my-game"),
                 QStringLiteral("game.exe = \"/tmp/my-game.exe\"\n"));

    ConfigFile *config = fx.configs->gameConfig(QStringLiteral("my-game"));
    QVERIFY(config != nullptr);
    QVERIFY(config->exists());
    QCOMPARE(config->valueFor(QStringLiteral("game.exe")),
             QStringLiteral("/tmp/my-game.exe"));

    // 带路径分隔符的 slug 仍必须拒绝。
    QVERIFY(fx.configs->gameConfig(QStringLiteral("../escape")) == nullptr);
}

void TestConfigManager::reportsUnsavedChanges()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("starrail"),
                 QStringLiteral("game.exe = \"/tmp/starrail.exe\"\n"));

    QVERIFY(!fx.configs->hasUnsavedChanges());
    ConfigFile *config = fx.configs->gameConfig(QStringLiteral("starrail"));
    QVERIFY(config != nullptr);
    QVERIFY(config->setValue(QStringLiteral("game.exe"), QStringLiteral("/tmp/other.exe")));
    QVERIFY(fx.configs->hasUnsavedChanges());

    // 未保存的新配置不能因为 load 而清零 dirty。
    QVERIFY(config->dirty());
}

void TestConfigManager::commonFieldsDropHostsDisconnect()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    const QStringList keys = fieldKeys(fx.configs->commonFields());
    QVERIFY(!keys.isEmpty());
    QVERIFY(!keys.contains(QStringLiteral("features.hosts_disconnect.enabled")));
    QVERIFY(!keys.contains(QStringLiteral("features.hosts_disconnect.content")));

    // 其余字段结构保持不变：key/title/group/type/description/hint。
    const QVariantMap mangohud =
            fieldByKey(fx.configs->commonFields(), QStringLiteral("mangohud.enabled"));
    QVERIFY(!mangohud.isEmpty());
    for (const QString &part : {QStringLiteral("key"), QStringLiteral("title"),
                                QStringLiteral("group"), QStringLiteral("type"),
                                QStringLiteral("description"), QStringLiteral("hint")}) {
        QVERIFY2(mangohud.contains(part), qPrintable(part));
    }
}

void TestConfigManager::gameFieldsForEndfieldAppendsSurrogateCatalog()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    const QVariantList base = fx.configs->gameFields();
    const QVariantList endfield = fx.configs->gameFieldsFor(QStringLiteral("endfield"));
    QCOMPARE(endfield.size(), base.size() + endfieldSurrogateKeys.size());

    // 基础字段原样保留且顺序不变。
    const QStringList baseKeys = fieldKeys(base);
    const QStringList allKeys = fieldKeys(endfield);
    QCOMPARE(allKeys.mid(0, baseKeys.size()), baseKeys);
    QCOMPARE(allKeys.mid(baseKeys.size()), endfieldSurrogateKeys);

    for (const QString &key : endfieldSurrogateKeys) {
        const QVariantMap map = fieldByKey(endfield, key);
        QVERIFY2(!map.isEmpty(), qPrintable(key));
        QCOMPARE(map.value(QStringLiteral("group")).toString(),
                 QStringLiteral("终末地替身"));
        for (const QString &part : {QStringLiteral("title"), QStringLiteral("type"),
                                    QStringLiteral("description"),
                                    QStringLiteral("hint")}) {
            QVERIFY2(map.contains(part), qPrintable(key + QLatin1Char('/') + part));
        }
    }

    const QVariantMap mode =
            fieldByKey(endfield, QStringLiteral("endfield.surrogate.mode"));
    QCOMPARE(mode.value(QStringLiteral("type")).toString(), QStringLiteral("enum"));
    QCOMPARE(mode.value(QStringLiteral("title")).toString(), QStringLiteral("替身模式"));
    const QVariantList options = mode.value(QStringLiteral("options")).toList();
    QStringList values;
    QStringList labels;
    for (const QVariant &item : options) {
        const QVariantMap option = item.toMap();
        QVERIFY(option.contains(QStringLiteral("value")));
        QVERIFY(option.contains(QStringLiteral("label")));
        values.append(option.value(QStringLiteral("value")).toString());
        labels.append(option.value(QStringLiteral("label")).toString());
    }
    QCOMPARE(values, QStringList({QString(), QStringLiteral("hardlink-or-copy"),
                                  QStringLiteral("hardlink"), QStringLiteral("copy"),
                                  QStringLiteral("launcher")}));
    QCOMPARE(labels, QStringList({QStringLiteral("未启用"),
                                  QStringLiteral("hardlink-or-copy"),
                                  QStringLiteral("hardlink"), QStringLiteral("copy"),
                                  QStringLiteral("launcher（挂起官方启动器）")}));

    // 类型目录符合契约。
    const QMap<QString, QString> expectedTypes = {
        {QStringLiteral("endfield.surrogate.launcher"), QStringLiteral("dir")},
        {QStringLiteral("endfield.surrogate.dir"), QStringLiteral("dir")},
        {QStringLiteral("endfield.surrogate.target"), QStringLiteral("file")},
        {QStringLiteral("endfield.surrogate.hardlink_dir"), QStringLiteral("dir")},
        {QStringLiteral("endfield.surrogate.hardlink_target"), QStringLiteral("file")},
        {QStringLiteral("endfield.surrogate.copy_dir"), QStringLiteral("dir")},
        {QStringLiteral("endfield.surrogate.copy_target"), QStringLiteral("file")},
        {QStringLiteral("endfield.surrogate.keep"), QStringLiteral("bool")},
        {QStringLiteral("endfield.surrogate.exit_after"), QStringLiteral("int")},
        {QStringLiteral("endfield.surrogate.show_info"), QStringLiteral("bool")},
    };
    for (auto it = expectedTypes.cbegin(); it != expectedTypes.cend(); ++it) {
        QCOMPARE(fieldByKey(endfield, it.key()).value(QStringLiteral("type")).toString(),
                 it.value());
    }
}

void TestConfigManager::gameFieldsForOtherGamesKeepsBaseCatalog()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    const QVariantList base = fx.configs->gameFields();
    QCOMPARE(fx.configs->gameFieldsFor(QStringLiteral("starrail")), base);
    QCOMPARE(fx.configs->gameFieldsFor(QString()), base);
    QCOMPARE(fx.configs->gameFieldsFor(QStringLiteral("endfield-ptr")), base);
}

void TestConfigManager::reportsHostsDisconnectResidualKeys()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeCommon(QStringLiteral("mangohud.enabled = true\n"
                                 "features.hosts_disconnect.enabled = true\n"
                                 "features.hosts_disconnect.content = \"0.0.0.0 log-upload.example\"\n"));
    fx.configs->reloadAll();

    const QVariantList issues = fx.configs->validateCommon();
    QVERIFY(hasIssue(issues, QStringLiteral("warning"),
                     QStringLiteral("features.hosts_disconnect")));
    // 旧的逐键提示必须消失。
    QVERIFY(!hasIssue(issues, QStringLiteral("warning"),
                      QStringLiteral("features.hosts_disconnect.enabled")));
    QVERIFY(!hasIssue(issues, QStringLiteral("warning"),
                      QStringLiteral("features.hosts_disconnect.content")));
}

void TestConfigManager::acceptsCommonWithoutHostsKeys()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeCommon(QStringLiteral("mangohud.enabled = true\n"));
    fx.configs->reloadAll();

    QVERIFY(!hasIssue(fx.configs->validateCommon(), QStringLiteral("warning"),
                      QStringLiteral("features.hosts_disconnect")));
}

void TestConfigManager::endfieldSurrogateModeMissing()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.dir = \"/games/endfield\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.mode")));
}

void TestConfigManager::endfieldSurrogateModeInvalid()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"magic\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.mode")));
}

void TestConfigManager::endfieldSurrogateDisabledIsClean()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"\"\n"));
    const QVariantList issues = fx.configs->validateGame(QStringLiteral("endfield"));
    QVERIFY(!hasIssue(issues, QStringLiteral("error"),
                      QStringLiteral("endfield.surrogate.mode")));
    QVERIFY(!hasError(issues));
}

void TestConfigManager::endfieldSurrogateDirTargetConflict()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"hardlink-or-copy\"\n"
                                "endfield.surrogate.dir = \"/games/endfield\"\n"
                                "endfield.surrogate.target = \"/games/endfield/Endfield.exe\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.dir")));

    // 只保留 dir 时不报错。
    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"hardlink-or-copy\"\n"
                                "endfield.surrogate.dir = \"/games/endfield\"\n"));
    fx.configs->gameConfig(QStringLiteral("endfield"))->load();
    QVERIFY(!hasError(fx.configs->validateGame(QStringLiteral("endfield"))));
}

void TestConfigManager::endfieldSurrogateHardlinkAndCopyConflicts()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"hardlink\"\n"
                                "endfield.surrogate.hardlink_dir = \"/games/endfield\"\n"
                                "endfield.surrogate.hardlink_target = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.copy_dir = \"/games/endfield\"\n"
                                "endfield.surrogate.copy_target = \"/games/endfield/Endfield.exe\"\n"));
    const QVariantList issues = fx.configs->validateGame(QStringLiteral("endfield"));
    QVERIFY(hasIssue(issues, QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.hardlink_dir")));
    QVERIFY(hasIssue(issues, QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.copy_dir")));
}

void TestConfigManager::endfieldLauncherModeRequiresLauncher()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"launcher\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.launcher")));
}

void TestConfigManager::endfieldLauncherModeRejectsSourceKeys()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"launcher\"\n"
                                "endfield.surrogate.launcher = \"/games/endfield/Games.exe\"\n"
                                "endfield.surrogate.dir = \"/games/endfield\"\n"
                                "endfield.surrogate.copy_target = \"/games/endfield/Endfield.exe\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.mode")));

    // 只有 launcher 时合法。
    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"launcher\"\n"
                                "endfield.surrogate.launcher = \"/games/endfield/Games.exe\"\n"));
    fx.configs->gameConfig(QStringLiteral("endfield"))->load();
    QVERIFY(!hasError(fx.configs->validateGame(QStringLiteral("endfield"))));
}

void TestConfigManager::endfieldExitAfterMustBePositiveInteger()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"copy\"\n"
                                "endfield.surrogate.copy_dir = \"/games/endfield\"\n"
                                "endfield.surrogate.exit_after = \"abc\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.exit_after")));

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"copy\"\n"
                                "endfield.surrogate.copy_dir = \"/games/endfield\"\n"
                                "endfield.surrogate.exit_after = 0\n"));
    fx.configs->gameConfig(QStringLiteral("endfield"))->load();
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                     QStringLiteral("error"),
                     QStringLiteral("endfield.surrogate.exit_after")));

    fx.writeGame(QStringLiteral("endfield"),
                 QStringLiteral("game.exe = \"/games/endfield/Endfield.exe\"\n"
                                "endfield.surrogate.mode = \"copy\"\n"
                                "endfield.surrogate.copy_dir = \"/games/endfield\"\n"
                                "endfield.surrogate.exit_after = 5\n"));
    fx.configs->gameConfig(QStringLiteral("endfield"))->load();
    QVERIFY(!hasIssue(fx.configs->validateGame(QStringLiteral("endfield")),
                      QStringLiteral("error"),
                      QStringLiteral("endfield.surrogate.exit_after")));
}

void TestConfigManager::endfieldSurrogateKeysIgnoredForOtherGames()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("starrail"),
                 QStringLiteral("game.exe = \"/games/starrail/StarRail.exe\"\n"
                                "endfield.surrogate.mode = \"magic\"\n"
                                "endfield.surrogate.dir = \"/games/endfield\"\n"
                                "endfield.surrogate.target = \"/games/endfield/Endfield.exe\"\n"));
    QVERIFY(!hasError(fx.configs->validateGame(QStringLiteral("starrail"))));
}

void TestConfigManager::warnsAboutRemovedFpsUnlockProg()
{
    Fixture fx;
    QVERIFY(fx.root.isValid());

    fx.writeGame(QStringLiteral("genshin"),
                 QStringLiteral("game.exe = \"/games/genshin/GenshinImpact.exe\"\n"
                                "gi.fps_unlock.prog = \"GenshinImpact.exe\"\n"));
    QVERIFY(hasIssue(fx.configs->validateGame(QStringLiteral("genshin")),
                     QStringLiteral("warning"),
                     QStringLiteral("gi.fps_unlock.prog")));

    fx.writeGame(QStringLiteral("starrail"),
                 QStringLiteral("game.exe = \"/games/starrail/StarRail.exe\"\n"));
    QVERIFY(!hasIssue(fx.configs->validateGame(QStringLiteral("starrail")),
                      QStringLiteral("warning"),
                      QStringLiteral("gi.fps_unlock.prog")));
}

QTEST_GUILESS_MAIN(TestConfigManager)

#include "tst_configmanager.moc"
