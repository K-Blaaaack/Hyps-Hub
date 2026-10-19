#include <QtTest>
#include <QTemporaryDir>

#include "adapter/configfile.h"

using namespace hyps;

class TestConfigFile : public QObject
{
    Q_OBJECT

private slots:
    void parsesUpstreamCommonConf();
    void parsesArraysAndSections();
    void editPreservesCommentsAndOrder();
    void saveCreatesBackup();
    void removeKeyOnlyRemovesTarget();
    void quotesPathsWithSpacesAndHash();
    void rawApplyAndValidation();
    void missingFileIsEmpty();
    void duplicateKeysReported();
};

namespace {

QString fixture(const QString &name)
{
    return QStringLiteral(HYPS_TEST_SOURCE_DIR "/fixtures/") + name;
}

QString copyFixture(const QTemporaryDir &dir, const QString &name)
{
    const QString target = dir.filePath(QStringLiteral("game.conf"));
    QFile::copy(fixture(name), target);
    return target;
}

} // namespace

void TestConfigFile::parsesUpstreamCommonConf()
{
    ConfigFile config(fixture(QStringLiteral("upstream-common.conf")));
    QVERIFY(config.load());
    // 上游示例把常用开关注释掉了，解析器应保持未设置状态。
    QVERIFY(!config.hasKey(QStringLiteral("mangohud.enabled")));
    QVERIFY(!config.hasKey(QStringLiteral("prepare.kill_wineserver")));
    QCOMPARE(config.valueFor(QStringLiteral("compile.CC")), QStringLiteral("gcc"));
    QCOMPARE(config.valueFor(QStringLiteral("compile.mingw.CC")),
             QStringLiteral("x86_64-w64-mingw32-gcc"));

    const QStringList flags = config.arrayValues(QStringLiteral("compile.CFLAGS"));
    QCOMPARE(flags, QStringList({QStringLiteral("-Wall"), QStringLiteral("-Wextra")}));
    QVERIFY(config.arrayValues(QStringLiteral("nvapi.drs.settings")).isEmpty());
}

void TestConfigFile::parsesArraysAndSections()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString path = dir.filePath(QStringLiteral("x.conf"));
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
    file.write("[game]\n"
               "exe = \"/tmp/my game/game.exe\"\n"
               "args = [\n"
               "    \"-dx12\",\n"
               "    \"-windowed\",\n"
               "]\n"
               "paren = ( a b c )\n");
    file.close();

    ConfigFile config(path);
    QVERIFY(config.load());
    QCOMPARE(config.valueFor(QStringLiteral("game.exe")),
             QStringLiteral("/tmp/my game/game.exe"));
    QCOMPARE(config.arrayValues(QStringLiteral("game.args")),
             QStringList({QStringLiteral("-dx12"), QStringLiteral("-windowed")}));
    QCOMPARE(config.arrayValues(QStringLiteral("game.paren")),
             QStringList({QStringLiteral("a"), QStringLiteral("b"), QStringLiteral("c")}));
}

void TestConfigFile::editPreservesCommentsAndOrder()
{
    ConfigFile config(fixture(QStringLiteral("upstream-common.conf")));
    QVERIFY(config.load());
    QVERIFY(config.setValue(QStringLiteral("compile.CC"), QStringLiteral("clang")));

    const QString text = config.text();
    QVERIFY(text.contains(QStringLiteral("# 编译用 C 写的小工具的编译选项")));
    QVERIFY(text.contains(QStringLiteral("# 通用配置")));
    QCOMPARE(config.valueFor(QStringLiteral("compile.CC")), QStringLiteral("clang"));

    // 无关键保持原值。
    QCOMPARE(config.valueFor(QStringLiteral("compile.mingw.CC")),
             QStringLiteral("x86_64-w64-mingw32-gcc"));
    QVERIFY(config.dirty());
}

void TestConfigFile::saveCreatesBackup()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString path = copyFixture(dir, QStringLiteral("upstream-common.conf"));
    const QByteArray original = [&]() {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly)) {
            return QByteArray();
        }
        return f.readAll();
    }();

    ConfigFile config(path);
    QVERIFY(config.load());
    config.setValue(QStringLiteral("cache.shader.enabled"), QStringLiteral("true"));
    const QVariantMap result = config.save();
    QVERIFY2(result.value(QStringLiteral("ok")).toBool(),
             qPrintable(result.value(QStringLiteral("error")).toString()));

    const QString backup = result.value(QStringLiteral("backup")).toString();
    QVERIFY(!backup.isEmpty());
    QVERIFY(QFile::exists(backup));

    QFile backupFile(backup);
    QVERIFY(backupFile.open(QIODevice::ReadOnly));
    QCOMPARE(backupFile.readAll(), original);

    ConfigFile reloaded(path);
    QVERIFY(reloaded.load());
    QCOMPARE(reloaded.valueFor(QStringLiteral("cache.shader.enabled")), QStringLiteral("true"));
    QVERIFY(!reloaded.dirty());
}

void TestConfigFile::removeKeyOnlyRemovesTarget()
{
    ConfigFile config(fixture(QStringLiteral("upstream-common.conf")));
    QVERIFY(config.load());
    QVERIFY(config.removeKey(QStringLiteral("compile.CC")));
    QVERIFY(!config.hasKey(QStringLiteral("compile.CC")));
    QVERIFY(config.hasKey(QStringLiteral("compile.CFLAGS")));
    QVERIFY(config.text().contains(QStringLiteral("# 编译用 C 写的小工具的编译选项")));
}

void TestConfigFile::quotesPathsWithSpacesAndHash()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString path = dir.filePath(QStringLiteral("p.conf"));
    {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.write("game.exe = \"\"\n");
    }

    ConfigFile config(path);
    QVERIFY(config.load());
    const QString value = QStringLiteral("/tmp/A B #1/game.exe");
    QVERIFY(config.setValue(QStringLiteral("game.exe"), value));
    QCOMPARE(config.valueFor(QStringLiteral("game.exe")), value);

    QVERIFY(config.save().value(QStringLiteral("ok")).toBool());
    ConfigFile reloaded(path);
    QVERIFY(reloaded.load());
    QCOMPARE(reloaded.valueFor(QStringLiteral("game.exe")), value);
}

void TestConfigFile::rawApplyAndValidation()
{
    ConfigFile config(fixture(QStringLiteral("upstream-common.conf")));
    QVERIFY(config.load());

    QVariantMap result = config.applyRawText(QStringLiteral("a = 1\nbroken line\nb = 2\n"));
    QVERIFY(result.value(QStringLiteral("ok")).toBool());
    QCOMPARE(config.valueFor(QStringLiteral("a")), QStringLiteral("1"));
    const QVariantList warnings = config.validate();
    QVERIFY(!warnings.isEmpty());
    QVERIFY(warnings.first().toMap().value(QStringLiteral("level")).toString()
            == QLatin1String("warning"));
}

void TestConfigFile::missingFileIsEmpty()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    ConfigFile config(dir.filePath(QStringLiteral("missing.conf")));
    QVERIFY(config.load());
    QVERIFY(!config.exists());
    QVERIFY(!config.dirty());
    QVERIFY(!config.hasKey(QStringLiteral("game.exe")));
}

void TestConfigFile::duplicateKeysReported()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString path = dir.filePath(QStringLiteral("dup.conf"));
    {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.write("key = first\nkey = second\n");
    }
    ConfigFile config(path);
    QVERIFY(config.load());
    QCOMPARE(config.valueFor(QStringLiteral("key")), QStringLiteral("second"));
    bool duplicateWarning = false;
    for (const QVariant &issue : config.validate()) {
        if (issue.toMap().value(QStringLiteral("key")).toString() == QLatin1String("key")) {
            duplicateWarning = true;
        }
    }
    QVERIFY(duplicateWarning);
}

QTEST_GUILESS_MAIN(TestConfigFile)

#include "tst_configfile.moc"
