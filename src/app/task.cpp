#include "app/task.h"

#include "app/logmodel.h"

namespace hyps {

Task::Task(QString id,
           QString kind,
           QString label,
           QString command,
           QString logPath,
           QString detail,
           QObject *parent)
    : QObject(parent)
    , m_id(std::move(id))
    , m_kind(std::move(kind))
    , m_label(std::move(label))
    , m_command(std::move(command))
    , m_logPath(std::move(logPath))
    , m_detail(std::move(detail))
    , m_log(new LogModel(this))
{
}

QString Task::stateId() const
{
    switch (m_state) {
    case State::Running:
        return QStringLiteral("running");
    case State::Succeeded:
        return QStringLiteral("succeeded");
    case State::Failed:
        return QStringLiteral("failed");
    case State::Canceled:
        return QStringLiteral("canceled");
    case State::TimedOut:
        return QStringLiteral("timeout");
    }
    return QStringLiteral("failed");
}

QString Task::stateText() const
{
    switch (m_state) {
    case State::Running:
        return tr("运行中");
    case State::Succeeded:
        return tr("已完成");
    case State::Failed:
        return tr("失败");
    case State::Canceled:
        return tr("已取消");
    case State::TimedOut:
        return tr("超时");
    }
    return tr("失败");
}

QString Task::durationText() const
{
    if (!m_startedAt.isValid()) {
        return {};
    }
    const QDateTime end = m_finishedAt.isValid() ? m_finishedAt : QDateTime::currentDateTime();
    const qint64 seconds = m_startedAt.msecsTo(end) / 1000;
    if (seconds < 60) {
        return tr("%1 秒").arg(seconds);
    }
    const qint64 minutes = seconds / 60;
    if (minutes < 60) {
        return tr("%1 分 %2 秒").arg(minutes).arg(seconds % 60);
    }
    return tr("%1 时 %2 分").arg(minutes / 60).arg(minutes % 60);
}

void Task::setStartedAt(const QDateTime &startedAt)
{
    m_startedAt = startedAt;
    emit changed();
}

void Task::setFinished(State state, int exitCode, bool hasExitCode)
{
    m_state = state;
    m_exitCode = exitCode;
    m_hasExitCode = hasExitCode;
    m_finishedAt = QDateTime::currentDateTime();
    emit changed();
}

void Task::setErrorSummary(const QString &summary)
{
    m_errorSummary = summary;
    emit changed();
}

void Task::appendCapturedStdout(const QString &chunk)
{
    constexpr int maxChars = 4 * 1024 * 1024;
    m_capturedStdout += chunk;
    if (m_capturedStdout.size() > maxChars) {
        m_capturedStdout.remove(0, m_capturedStdout.size() - maxChars);
    }
}

void Task::appendStderrTail(const QString &chunk)
{
    constexpr int maxChars = 16 * 1024;
    m_stderrTail += chunk;
    if (m_stderrTail.size() > maxChars) {
        m_stderrTail.remove(0, m_stderrTail.size() - maxChars);
    }
}

void Task::markLoadedFromHistory(State state,
                                 const QDateTime &startedAt,
                                 const QDateTime &finishedAt,
                                 int exitCode,
                                 bool hasExitCode,
                                 const QString &errorSummary)
{
    m_state = state;
    m_startedAt = startedAt;
    m_finishedAt = finishedAt;
    m_exitCode = exitCode;
    m_hasExitCode = hasExitCode;
    m_errorSummary = errorSummary;
    emit changed();
}

} // namespace hyps
