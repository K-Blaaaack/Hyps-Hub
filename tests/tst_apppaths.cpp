#include <QtTest>

#include "app/apppaths.h"

using namespace hyps;

class TestAppPaths : public QObject
{
    Q_OBJECT

private slots:
    void defaultXdgLayout();
    void explicitXdgAndOverrides();
    void relativeXdgIsIgnored();
    void isolationEnvironment();
    void directoriesListed();
};

namespace {

QProcessEnvironment baseEnvironment()
{
    QProcessEnvironment env;
    env.insert(QStringLiteral("HOME"), QStringLiteral("/home/tester"));
    return env;
}

} // namespace

void TestAppPaths::defaultXdgLayout()
{
    AppPaths paths(baseEnvironment());
    QCOMPARE(paths.dataDir(), QStringLiteral("/home/tester/.local/share/hyps-hub"));
    QCOMPARE(paths.configDir(), QStringLiteral("/home/tester/.config/hyps-hub"));
    QCOMPARE(paths.stateDir(), QStringLiteral("/home/tester/.local/state/hyps-hub"));
    QCOMPARE(paths.runtimeDir(), QStringLiteral("/home/tester/.local/share/hyps-hub/runtime/Hyps"));
    QCOMPARE(paths.hypsConfigDir(), QStringLiteral("/home/tester/.config/hyps-hub/hyps"));
    QCOMPARE(paths.hypsDataDir(), QStringLiteral("/home/tester/.local/share/hyps-hub/hyps-data"));
    QCOMPARE(paths.hypsTempDir(),
             QStringLiteral("/home/tester/.local/share/hyps-hub/cache/hyps-tmp"));
}

void TestAppPaths::explicitXdgAndOverrides()
{
    QProcessEnvironment env = baseEnvironment();
    env.insert(QStringLiteral("XDG_DATA_HOME"), QStringLiteral("/srv/data/"));
    env.insert(QStringLiteral("XDG_CONFIG_HOME"), QStringLiteral("/srv/config"));
    env.insert(QStringLiteral("XDG_STATE_HOME"), QStringLiteral("/srv/state"));

    AppPaths paths(env);
    QCOMPARE(paths.dataDir(), QStringLiteral("/srv/data/hyps-hub"));
    QCOMPARE(paths.configDir(), QStringLiteral("/srv/config/hyps-hub"));
    QCOMPARE(paths.stateDir(), QStringLiteral("/srv/state/hyps-hub"));

    QProcessEnvironment overrideEnv = env;
    overrideEnv.insert(QStringLiteral("HYPS_HUB_DATA_DIR"), QStringLiteral("/tmp/custom-data"));
    overrideEnv.insert(QStringLiteral("HYPS_HUB_CONFIG_DIR"), QStringLiteral("/tmp/custom-config"));
    overrideEnv.insert(QStringLiteral("HYPS_HUB_STATE_DIR"), QStringLiteral("/tmp/custom-state"));

    AppPaths overridden(overrideEnv);
    QCOMPARE(overridden.dataDir(), QStringLiteral("/tmp/custom-data"));
    QCOMPARE(overridden.runtimeDir(), QStringLiteral("/tmp/custom-data/runtime/Hyps"));
    QCOMPARE(overridden.configDir(), QStringLiteral("/tmp/custom-config"));
    QCOMPARE(overridden.stateDir(), QStringLiteral("/tmp/custom-state"));
}

void TestAppPaths::relativeXdgIsIgnored()
{
    QProcessEnvironment env = baseEnvironment();
    env.insert(QStringLiteral("XDG_DATA_HOME"), QStringLiteral("../relative"));

    AppPaths paths(env);
    QCOMPARE(paths.dataDir(), QStringLiteral("/home/tester/.local/share/hyps-hub"));
}

void TestAppPaths::isolationEnvironment()
{
    QProcessEnvironment env = baseEnvironment();
    env.insert(QStringLiteral("XDG_CONFIG_HOME"), QStringLiteral("/srv/config"));
    env.insert(QStringLiteral("XDG_CACHE_HOME"), QStringLiteral("/srv/cache"));

    AppPaths paths(env);
    const QProcessEnvironment cli = paths.hypsEnvironment();
    QCOMPARE(cli.value(QStringLiteral("CONFIG_DIR")), paths.hypsConfigDir());
    QCOMPARE(cli.value(QStringLiteral("CACHE_DIR")), paths.hypsCacheDir());
    QCOMPARE(cli.value(QStringLiteral("DATA_DIR")), paths.hypsDataDir());
    QCOMPARE(cli.value(QStringLiteral("TEMP_DIR")), paths.hypsTempDir());
    QCOMPARE(cli.value(QStringLiteral("NO_COLOR")), QStringLiteral("1"));
    QVERIFY(!cli.value(QStringLiteral("CONFIG_DIR")).contains(QStringLiteral("~/Hyps")));
}

void TestAppPaths::directoriesListed()
{
    AppPaths paths(baseEnvironment());
    const QVariantList dirs = paths.directories();
    QVERIFY(dirs.size() >= 8);
    for (const QVariant &entry : dirs) {
        const QVariantMap map = entry.toMap();
        QVERIFY(!map.value(QStringLiteral("name")).toString().isEmpty());
        QVERIFY(map.value(QStringLiteral("path")).toString().startsWith(QLatin1Char('/')));
    }
}

QTEST_GUILESS_MAIN(TestAppPaths)

#include "tst_apppaths.moc"
