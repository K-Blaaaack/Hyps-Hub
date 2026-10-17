#pragma once

#include <QObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QString>
#include <QStringDecoder>
#include <QStringList>
#include <QTimer>

namespace hyps {

/**
 * 安全的外部进程执行器。
 *
 * - 使用程序 + 参数数组，永远不经过 shell；
 * - 独立进程组，取消/超时时向整个进程组发 SIGTERM，宽限期后 SIGKILL，
 *   避免 umu-run / 游戏等子进程残留；
 * - stdout/stderr 分通道采集，增量 UTF-8 解码（不假设固定编码）；
 * - 支持工作目录、环境变量、超时。
 */
class ProcessRunner : public QObject
{
    Q_OBJECT

public:
    explicit ProcessRunner(QObject *parent = nullptr);
    ~ProcessRunner() override;

    bool start(const QString &program,
               const QStringList &arguments,
               const QString &workingDirectory,
               const QProcessEnvironment &environment,
               int timeoutMs = 0);

    void cancel();
    bool isRunning() const;
    qint64 processId() const;
    int exitCode() const;
    bool wasCanceled() const { return m_cancelRequested; }
    bool wasTimedOut() const { return m_timedOut; }

    QString program() const { return m_program; }
    QStringList arguments() const { return m_arguments; }

    /** 仅用于界面显示的可读命令预览，不参与执行。 */
    static QString formatCommand(const QString &program, const QStringList &arguments);

signals:
    void started();
    void standardOutput(const QString &text);
    void standardError(const QString &text);
    void finished(int exitCode, QProcess::ExitStatus exitStatus, bool canceled, bool timedOut);
    void failedToStart(const QString &message);

private:
    void handleStartFailure(const QString &message);
    void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void pumpStdout();
    void pumpStderr();
    void sendSignalToGroup(int signal);
    void forceKill();
    void cleanupProcess();

    QProcess *m_process = nullptr;
    QStringDecoder m_outDecoder{QStringDecoder::Utf8};
    QStringDecoder m_errDecoder{QStringDecoder::Utf8};
    QString m_program;
    QStringList m_arguments;
    QTimer m_killTimer;
    QTimer m_timeoutTimer;
    bool m_cancelRequested = false;
    bool m_timedOut = false;
    bool m_finished = false;
};

} // namespace hyps
