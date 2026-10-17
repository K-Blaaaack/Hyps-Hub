#include "adapter/processrunner.h"

#include <QFileInfo>
#include <QRegularExpression>
#include <QTimer>

#include <csignal>
#include <unistd.h>

namespace hyps {

ProcessRunner::ProcessRunner(QObject *parent)
    : QObject(parent)
{
    m_killTimer.setSingleShot(true);
    m_killTimer.setInterval(1500);
    connect(&m_killTimer, &QTimer::timeout, this, &ProcessRunner::forceKill);

    m_timeoutTimer.setSingleShot(true);
    connect(&m_timeoutTimer, &QTimer::timeout, this, [this]() {
        if (!m_process) {
            return;
        }
        m_timedOut = true;
        m_cancelRequested = true;
        sendSignalToGroup(SIGTERM);
        m_killTimer.start();
    });
}

ProcessRunner::~ProcessRunner()
{
    if (m_process) {
        m_cancelRequested = true;
        sendSignalToGroup(SIGTERM);
        if (!m_process->waitForFinished(1500)) {
            sendSignalToGroup(SIGKILL);
            m_process->waitForFinished(1000);
        }
        cleanupProcess();
    }
}

bool ProcessRunner::start(const QString &program,
                          const QStringList &arguments,
                          const QString &workingDirectory,
                          const QProcessEnvironment &environment,
                          int timeoutMs)
{
    if (m_process) {
        return false;
    }
    m_program = program;
    m_arguments = arguments;
    m_finished = false;
    m_cancelRequested = false;
    m_timedOut = false;

    if (program.isEmpty()) {
        QTimer::singleShot(0, this, [this]() {
            handleStartFailure(tr("未指定要执行的程序"));
        });
        return true;
    }

    if (!workingDirectory.isEmpty()) {
        const QFileInfo info(workingDirectory);
        if (!info.exists() || !info.isDir()) {
            const QString message = tr("工作目录不存在：%1").arg(workingDirectory);
            QTimer::singleShot(0, this, [this, message]() { handleStartFailure(message); });
            return true;
        }
    }

    m_process = new QProcess(this);
    m_process->setProgram(program);
    m_process->setArguments(arguments);
    m_process->setWorkingDirectory(workingDirectory);
    m_process->setProcessEnvironment(environment);
    m_process->setProcessChannelMode(QProcess::SeparateChannels);
    m_process->setInputChannelMode(QProcess::ManagedInputChannel);

#ifdef Q_OS_UNIX
    // 独立进程组：取消时可以连同游戏/umu-run 一起终止。
    m_process->setChildProcessModifier([]() { ::setpgid(0, 0); });
#endif

    connect(m_process, &QProcess::started, this, &ProcessRunner::started);
    connect(m_process, &QProcess::readyReadStandardOutput, this, &ProcessRunner::pumpStdout);
    connect(m_process, &QProcess::readyReadStandardError, this, &ProcessRunner::pumpStderr);
    connect(m_process, &QProcess::finished, this, &ProcessRunner::handleFinished);
    connect(m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            handleStartFailure(
                    tr("无法启动进程：%1").arg(m_process ? m_process->errorString()
                                                         : tr("未知错误")));
        }
    });

    m_process->start();

    if (timeoutMs > 0) {
        m_timeoutTimer.start(timeoutMs);
    }
    return true;
}

void ProcessRunner::pumpStdout()
{
    if (!m_process) {
        return;
    }
    const QByteArray data = m_process->readAllStandardOutput();
    if (data.isEmpty()) {
        return;
    }
    const QString text = m_outDecoder(data);
    if (!text.isEmpty()) {
        emit standardOutput(text);
    }
}

void ProcessRunner::pumpStderr()
{
    if (!m_process) {
        return;
    }
    const QByteArray data = m_process->readAllStandardError();
    if (data.isEmpty()) {
        return;
    }
    const QString text = m_errDecoder(data);
    if (!text.isEmpty()) {
        emit standardError(text);
    }
}

void ProcessRunner::handleFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    if (m_finished) {
        return;
    }
    m_finished = true;
    m_timeoutTimer.stop();
    m_killTimer.stop();

    pumpStdout();
    pumpStderr();

    const bool canceled = m_cancelRequested;
    const bool timedOut = m_timedOut;
    cleanupProcess();

    emit finished(exitCode, exitStatus, canceled, timedOut);
}

void ProcessRunner::handleStartFailure(const QString &message)
{
    if (m_finished) {
        return;
    }
    m_finished = true;
    m_timeoutTimer.stop();
    m_killTimer.stop();
    cleanupProcess();
    emit failedToStart(message);
}

void ProcessRunner::cleanupProcess()
{
    if (!m_process) {
        return;
    }
    m_process->disconnect(this);
    m_process->deleteLater();
    m_process = nullptr;
}

void ProcessRunner::sendSignalToGroup(int signal)
{
    if (!m_process) {
        return;
    }
    const qint64 pid = m_process->processId();
    if (pid <= 0) {
        return;
    }
#ifdef Q_OS_UNIX
    // 进程组 ID 等于子进程 PID（见 setChildProcessModifier）。
    if (::kill(-static_cast<pid_t>(pid), signal) != 0) {
        ::kill(static_cast<pid_t>(pid), signal);
    }
#else
    Q_UNUSED(signal);
#endif
}

void ProcessRunner::forceKill()
{
    if (!m_process) {
        return;
    }
    sendSignalToGroup(SIGKILL);
}

void ProcessRunner::cancel()
{
    if (!m_process || m_finished) {
        return;
    }
    m_cancelRequested = true;
    sendSignalToGroup(SIGTERM);
    m_killTimer.start();
}

bool ProcessRunner::isRunning() const
{
    return m_process != nullptr && !m_finished
            && m_process->state() != QProcess::NotRunning;
}

qint64 ProcessRunner::processId() const
{
    return m_process ? m_process->processId() : 0;
}

int ProcessRunner::exitCode() const
{
    return m_process ? m_process->exitCode() : -1;
}

QString ProcessRunner::formatCommand(const QString &program, const QStringList &arguments)
{
    auto quote = [](const QString &value) -> QString {
        if (value.isEmpty()
            || value.contains(QRegularExpression(QStringLiteral("[\\s'\"\\\\$`]")))) {
            QString escaped = value;
            escaped.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
            return QString(QLatin1Char('\'') + escaped + QLatin1Char('\''));
        }
        return value;
    };

    QString result = quote(program);
    for (const QString &argument : arguments) {
        result += QLatin1Char(' ');
        result += quote(argument);
    }
    return result;
}

} // namespace hyps
