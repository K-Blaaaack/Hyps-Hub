#pragma once

#include <QDateTime>
#include <QObject>
#include <QProcessEnvironment>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include <functional>

namespace hyps {

class AppPaths;
class ProcessRunner;

/**
 * 独立 Hyps 组件的管理者。
 *
 * 职责：首次克隆（异步、进度、失败清理）、结构校验、Git 信息读取、
 * 手动更新（仅 fetch + merge --ff-only，脏工作区拒绝）。
 *
 * 绝不使用 reset --hard / clean / checkout 覆盖用户修改；
 * 绝不操作 ~/Hyps 或任何未经确认的目录。
 */
class RuntimeManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString runtimePath READ runtimePath CONSTANT)
    Q_PROPERTY(QString repositoryUrl READ repositoryUrl CONSTANT)

    Q_PROPERTY(QString commit READ commit NOTIFY infoChanged)
    Q_PROPERTY(QString commitShort READ commitShort NOTIFY infoChanged)
    Q_PROPERTY(QString commitSubject READ commitSubject NOTIFY infoChanged)
    Q_PROPERTY(QString commitDate READ commitDate NOTIFY infoChanged)
    Q_PROPERTY(QString branch READ branch NOTIFY infoChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY infoChanged)
    Q_PROPERTY(QVariantMap info READ info NOTIFY infoChanged)

    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString progressText READ progressText NOTIFY progressChanged)
    Q_PROPERTY(QVariantList prerequisites READ prerequisites NOTIFY prerequisitesChanged)
    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(QString networkDetail READ networkDetail NOTIFY networkStatusChanged)

    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateStateChanged)
    Q_PROPERTY(QString upstreamCommit READ upstreamCommit NOTIFY updateStateChanged)
    Q_PROPERTY(QString upstreamSubject READ upstreamSubject NOTIFY updateStateChanged)
    Q_PROPERTY(QString upstreamDate READ upstreamDate NOTIFY updateStateChanged)
    Q_PROPERTY(QString updateStatusText READ updateStatusText NOTIFY updateStateChanged)
    Q_PROPERTY(int behindCount READ behindCount NOTIFY updateStateChanged)
    Q_PROPERTY(int aheadCount READ aheadCount NOTIFY updateStateChanged)
    Q_PROPERTY(QStringList logLines READ logLines NOTIFY logLinesChanged)

public:
    explicit RuntimeManager(AppPaths *paths, QObject *parent = nullptr);

    QString state() const { return m_state; }
    bool ready() const { return m_state == QLatin1String("ready"); }
    bool busy() const;
    QString errorMessage() const { return m_errorMessage; }
    QString runtimePath() const;
    QString repositoryUrl() const { return m_repositoryUrl; }

    QString commit() const { return m_commit; }
    QString commitShort() const { return m_commitShort; }
    QString commitSubject() const { return m_commitSubject; }
    QString commitDate() const { return m_commitDate; }
    QString branch() const { return m_branch; }
    bool dirty() const { return m_dirty; }
    QVariantMap info() const { return m_info; }

    double progress() const { return m_progress; }
    QString progressText() const { return m_progressText; }
    QVariantList prerequisites() const { return m_prerequisites; }
    QString networkStatus() const { return m_networkStatus; }
    QString networkDetail() const { return m_networkDetail; }

    bool updateAvailable() const { return m_updateAvailable; }
    QString upstreamCommit() const { return m_upstreamCommit; }
    QString upstreamSubject() const { return m_upstreamSubject; }
    QString upstreamDate() const { return m_upstreamDate; }
    QString updateStatusText() const { return m_updateStatusText; }
    int behindCount() const { return m_behindCount; }
    int aheadCount() const { return m_aheadCount; }
    QStringList logLines() const { return m_logLines; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void refreshPrerequisites();
    Q_INVOKABLE void checkNetwork();
    Q_INVOKABLE void startClone();
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void applyUpdate();
    Q_INVOKABLE void cancelOperation();
    Q_INVOKABLE void clearLogView();

    /** 校验仓库结构；返回 false 时 missing 包含缺失项。 */
    static bool verifyStructure(const QString &runtimeDir, QStringList *missing);

    // 测试注入：默认 "git" 与编译期上游 URL。
    void setGitProgramForTesting(const QString &program) { m_gitProgram = program; }
    void setRepositoryUrlForTesting(const QString &url) { m_repositoryUrl = url; }
    QString gitProgram() const { return m_gitProgram; }

signals:
    void stateChanged();
    void busyChanged();
    void errorMessageChanged();
    void infoChanged();
    void progressChanged();
    void prerequisitesChanged();
    void networkStatusChanged();
    void updateStateChanged();
    void logLinesChanged();
    void initialized();
    void updateFinished(bool success);

private:
    using CommandDone =
            std::function<void(int exitCode, const QString &out, const QString &err,
                               bool canceled)>;
    using OutputHandler = std::function<void(const QString &text, bool isStderr)>;

    void setState(const QString &state);
    void setErrorMessage(const QString &message);
    void clearError();
    void setProgress(double value, const QString &text = QString());
    void appendLog(const QString &line);
    void appendRuntimeLogFile(const QString &line);
    void writeRuntimeInfo(bool markInitialized, bool markUpdated = false);
    void readRuntimeInfo();
    void writeUpdateHistory(const QString &result, const QString &before, const QString &after,
                            const QString &detail);
    void loadGitInfo(std::function<void(bool, QString)> done);
    void runGit(const QStringList &arguments, int timeoutMs, OutputHandler onOutput,
                CommandDone done);
    void runCommand(const QString &program, const QStringList &arguments,
                    const QString &workingDirectory, int timeoutMs, OutputHandler onOutput,
                    CommandDone done);
    void finishOperation();
    void setNetworkStatus(const QString &status, const QString &detail);
    void handleCloneOutput(const QString &text);
    void handleCloneFinished(int exitCode, bool canceled, bool timedOut);
    void processCloneLine(const QString &line);
    void cleanupCloneDirectory();
    void refreshPrerequisitesInternal();
    QString defaultBranchName() const;
    QString stderrTail(const QString &text) const;

    AppPaths *m_paths = nullptr;
    QString m_state = QStringLiteral("missing");
    QString m_errorMessage;
    QString m_commit;
    QString m_commitShort;
    QString m_commitSubject;
    QString m_commitDate;
    QString m_branch;
    bool m_dirty = false;
    QVariantMap m_info;

    double m_progress = 0.0;
    QString m_progressText;
    QVariantList m_prerequisites;
    QString m_networkStatus = QStringLiteral("idle");
    QString m_networkDetail;

    bool m_updateAvailable = false;
    QString m_upstreamCommit;
    QString m_upstreamSubject;
    QString m_upstreamDate;
    QString m_updateStatusText;
    int m_behindCount = 0;
    int m_aheadCount = 0;
    QStringList m_logLines;

    QString m_gitProgram = QStringLiteral("git");
    QString m_repositoryUrl;
    ProcessRunner *m_commandRunner = nullptr;
    ProcessRunner *m_cloneRunner = nullptr;
    QString m_cloneDirectory;
    QString m_cloneBuffer;
    QString m_cloneTail;
    QString m_lastCloneLine;
    QString m_operation;
    int m_clonePercentShown = -1;
    bool m_cloneCanceled = false;
};

} // namespace hyps
