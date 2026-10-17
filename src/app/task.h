#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>

namespace hyps {

class LogModel;

/** 一次外部命令执行（或一个逻辑操作）的运行时状态。 */
class Task : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString kind READ kind CONSTANT)
    Q_PROPERTY(QString label READ label CONSTANT)
    Q_PROPERTY(QString command READ command CONSTANT)
    Q_PROPERTY(QString state READ stateId NOTIFY changed)
    Q_PROPERTY(QString stateText READ stateText NOTIFY changed)
    Q_PROPERTY(QDateTime startedAt READ startedAt NOTIFY changed)
    Q_PROPERTY(QDateTime finishedAt READ finishedAt NOTIFY changed)
    Q_PROPERTY(QString durationText READ durationText NOTIFY changed)
    Q_PROPERTY(int exitCode READ exitCode NOTIFY changed)
    Q_PROPERTY(bool hasExitCode READ hasExitCode NOTIFY changed)
    Q_PROPERTY(QString errorSummary READ errorSummary NOTIFY changed)
    Q_PROPERTY(QString logPath READ logPath CONSTANT)
    Q_PROPERTY(QString detail READ detail CONSTANT)
    Q_PROPERTY(bool active READ active NOTIFY changed)
    Q_PROPERTY(bool cancelable READ cancelable NOTIFY changed)
    Q_PROPERTY(hyps::LogModel *log READ log CONSTANT)

public:
    enum class State { Running, Succeeded, Failed, Canceled, TimedOut };
    Q_ENUM(State)

    explicit Task(QString id,
                  QString kind,
                  QString label,
                  QString command,
                  QString logPath,
                  QString detail = {},
                  QObject *parent = nullptr);

    QString id() const { return m_id; }
    QString kind() const { return m_kind; }
    QString label() const { return m_label; }
    QString command() const { return m_command; }
    QString logPath() const { return m_logPath; }
    QString detail() const { return m_detail; }

    LogModel *log() const { return m_log; }

    State state() const { return m_state; }
    QString stateId() const;
    QString stateText() const;
    bool active() const { return m_state == State::Running; }
    bool cancelable() const { return m_state == State::Running; }

    QDateTime startedAt() const { return m_startedAt; }
    QDateTime finishedAt() const { return m_finishedAt; }
    QString durationText() const;

    int exitCode() const { return m_exitCode; }
    bool hasExitCode() const { return m_hasExitCode; }

    QString errorSummary() const { return m_errorSummary; }

    void setStartedAt(const QDateTime &startedAt);
    void setFinished(State state, int exitCode, bool hasExitCode);
    void setErrorSummary(const QString &summary);

    void setProbe(bool probe) { m_probe = probe; }
    bool probe() const { return m_probe; }

    /** 环境检测等需要读取 stdout 的场景使用；有上限，避免内存膨胀。 */
    void appendCapturedStdout(const QString &chunk);
    QString capturedStdout() const { return m_capturedStdout; }

    /** 保留 stderr 尾部若干行，用于错误摘要。 */
    void appendStderrTail(const QString &chunk);
    QString stderrTail() const { return m_stderrTail; }

    void markLoadedFromHistory(State state,
                               const QDateTime &startedAt,
                               const QDateTime &finishedAt,
                               int exitCode,
                               bool hasExitCode,
                               const QString &errorSummary);

signals:
    void changed();

private:
    QString m_id;
    QString m_kind;
    QString m_label;
    QString m_command;
    QString m_logPath;
    QString m_detail;
    LogModel *m_log = nullptr;

    State m_state = State::Running;
    QDateTime m_startedAt;
    QDateTime m_finishedAt;
    int m_exitCode = 0;
    bool m_hasExitCode = false;
    bool m_probe = false;
    QString m_errorSummary;
    QString m_capturedStdout;
    QString m_stderrTail;
};

} // namespace hyps
