#include <QtTest>
#include <QElapsedTimer>
#include <QProcessEnvironment>
#include <QSignalSpy>
#include <QTemporaryDir>

#include "adapter/processrunner.h"

using namespace hyps;

class TestProcessRunner : public QObject
{
    Q_OBJECT

private slots:
    void capturesStreamsAndExitCode();
    void passesArgumentsWithoutShell();
    void passesEnvironmentAndWorkingDirectory();
    void cancelsLongRunningProcess();
    void respectsTimeout();
    void reportsStartFailure();
    void handlesNonUtf8Output();
    void survivesPathWithSpaces();

private:
    QString writeScript(const QTemporaryDir &dir, const QString &name, const QByteArray &body);
};

QString TestProcessRunner::writeScript(const QTemporaryDir &dir, const QString &name,
                                       const QByteArray &body)
{
    const QString path = dir.filePath(name);
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return {};
    }
    file.write("#!/usr/bin/env bash\n");
    file.write(body);
    file.close();
    file.setPermissions(file.permissions() | QFileDevice::ExeOwner | QFileDevice::ExeUser);
    return path;
}

void TestProcessRunner::capturesStreamsAndExitCode()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("streams.sh"),
                                       "echo \"hello stdout\"\n"
                                       "echo \"hello stderr\" >&2\n"
                                       "exit 3\n");
    QVERIFY(!script.isEmpty());

    ProcessRunner runner;
    QString out;
    QString err;
    connect(&runner, &ProcessRunner::standardOutput, this,
            [&out](const QString &text) { out += text; });
    connect(&runner, &ProcessRunner::standardError, this,
            [&err](const QString &text) { err += text; });
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, dir.path(),
                         QProcessEnvironment::systemEnvironment(), 5000));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);

    QCOMPARE(finished.at(0).at(0).toInt(), 3);
    QVERIFY(out.contains(QStringLiteral("hello stdout")));
    QVERIFY(err.contains(QStringLiteral("hello stderr")));
    QVERIFY(!finished.at(0).at(2).toBool()); // canceled
    QVERIFY(!finished.at(0).at(3).toBool()); // timed out
}

void TestProcessRunner::passesArgumentsWithoutShell()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("args.sh"),
                                       "printf '%s|%s\\n' \"$#\" \"$1\"\n");
    ProcessRunner runner;
    QString out;
    connect(&runner, &ProcessRunner::standardOutput, this,
            [&out](const QString &text) { out += text; });
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    const QString dangerous = QStringLiteral("a b; touch /tmp/should-not-exist $(id)");
    QVERIFY(runner.start(QStringLiteral("bash"), {script, dangerous}, dir.path(),
                         QProcessEnvironment::systemEnvironment(), 5000));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);

    QCOMPARE(finished.at(0).at(0).toInt(), 0);
    const QStringList lines = out.trimmed().split(QLatin1Char('\n'));
    QCOMPARE(lines.size(), 1);
    QVERIFY(lines.first().startsWith(QStringLiteral("1|")));
    QCOMPARE(lines.first().mid(2), dangerous);
    QVERIFY(!QFile::exists(QStringLiteral("/tmp/should-not-exist")));
}

void TestProcessRunner::passesEnvironmentAndWorkingDirectory()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("env.sh"),
                                       "printf '%s\\n' \"$FOO\"\n"
                                       "printf '%s\\n' \"$PWD\"\n");
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("FOO"), QStringLiteral("bar-value"));

    ProcessRunner runner;
    QString out;
    connect(&runner, &ProcessRunner::standardOutput, this,
            [&out](const QString &text) { out += text; });
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, dir.path(), env, 5000));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);

    const QStringList lines = out.trimmed().split(QLatin1Char('\n'));
    QCOMPARE(lines.value(0), QStringLiteral("bar-value"));
    QCOMPARE(QFileInfo(lines.value(1)).canonicalFilePath(),
             QFileInfo(dir.path()).canonicalFilePath());
}

void TestProcessRunner::cancelsLongRunningProcess()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("long.sh"),
                                       "sleep 30 &\n"
                                       "child=$!\n"
                                       "wait $child\n");
    ProcessRunner runner;
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, dir.path(),
                         QProcessEnvironment::systemEnvironment(), 0));
    QTRY_VERIFY_WITH_TIMEOUT(runner.isRunning(), 3000);
    QElapsedTimer timer;
    timer.start();
    runner.cancel();
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);
    QVERIFY(timer.elapsed() < 4000);
    QVERIFY(finished.at(0).at(2).toBool()); // canceled
}

void TestProcessRunner::respectsTimeout()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("timeout.sh"), "sleep 10\n");
    ProcessRunner runner;
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, dir.path(),
                         QProcessEnvironment::systemEnvironment(), 400));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 6000);
    QVERIFY(finished.at(0).at(3).toBool()); // timed out
}

void TestProcessRunner::reportsStartFailure()
{
    ProcessRunner runner;
    QSignalSpy failed(&runner, &ProcessRunner::failedToStart);
    QVERIFY(runner.start(QStringLiteral("/nonexistent/hyps-hub-test-binary"), {}, QString(),
                         QProcessEnvironment::systemEnvironment(), 1000));
    QTRY_COMPARE_WITH_TIMEOUT(failed.count(), 1, 5000);
    QVERIFY(!failed.at(0).at(0).toString().isEmpty());
}

void TestProcessRunner::handlesNonUtf8Output()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString script = writeScript(dir, QStringLiteral("raw.sh"),
                                       "printf '\\xff\\xfe bytes\\n'\n");
    ProcessRunner runner;
    QString out;
    connect(&runner, &ProcessRunner::standardOutput, this,
            [&out](const QString &text) { out += text; });
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, dir.path(),
                         QProcessEnvironment::systemEnvironment(), 5000));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);
    QCOMPARE(finished.at(0).at(0).toInt(), 0);
    QVERIFY(out.contains(QStringLiteral("bytes")));
}

void TestProcessRunner::survivesPathWithSpaces()
{
    QTemporaryDir base;
    QVERIFY(base.isValid());
    const QString spaced = base.filePath(QStringLiteral("dir with spaces"));
    QVERIFY(QDir().mkpath(spaced));
    const QString script = writeScript(base, QStringLiteral("dir with spaces/space script.sh"),
                                       "echo spaced-ok\n");

    ProcessRunner runner;
    QString out;
    connect(&runner, &ProcessRunner::standardOutput, this,
            [&out](const QString &text) { out += text; });
    QSignalSpy finished(&runner, &ProcessRunner::finished);

    QVERIFY(runner.start(QStringLiteral("bash"), {script}, spaced,
                         QProcessEnvironment::systemEnvironment(), 5000));
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(), 1, 5000);
    QCOMPARE(finished.at(0).at(0).toInt(), 0);
    QVERIFY(out.contains(QStringLiteral("spaced-ok")));
}

QTEST_GUILESS_MAIN(TestProcessRunner)

#include "tst_processrunner.moc"
