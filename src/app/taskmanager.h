#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QHash>
#include <QObject>
#include <QProcessEnvironment>
#include <QStringList>
#include <QVariantList>
#include <QVector>

#include "app/task.h"

namespace hyps {

class AppPaths;
class ProcessRunner;
struct TaskContext;

/** 任务描述：由适配层构造，TaskManager 负责执行、记录和状态管理。 */
struct TaskSpec
{
    QString kind;
    QString label;
    QString program;
    QStringList arguments;
    QString workingDirectory;
    QProcessEnvironment environment;
    int timeoutMs = 0;
    bool probe = false;
    QString detail;
};

class TaskListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        KindRole,
        LabelRole,
        StateRole,
        StateTextRole,
        StartedRole,
        FinishedRole,
        DurationRole,
        ExitCodeRole,
        HasExitRole,
        CommandRole,
        ErrorRole,
        ActiveRole,
        LogPathRole,
        DetailRole,
    };

    explicit TaskListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int count() const { return rowCount(); }
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addTask(Task *task);
    void removeTask(Task *task);
    Task *taskAt(int row) const;
    int rowOf(Task *task) const;
    QVector<Task *> tasks() const { return m_tasks; }
    void notifyTask(Task *task);

signals:
    void countChanged();

private:
    QVector<Task *> m_tasks;
};

/**
 * 任务管理：启动/取消外部命令、实时日志、任务历史、进程清理。
 *
 * 任务历史写入 $XDG_STATE_HOME/hyps-hub/tasks.jsonl，最多保留 200 条；
 * 每个任务的完整输出写入 $XDG_DATA_HOME/hyps-hub/logs/tasks/。
 */
class TaskManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QAbstractItemModel *tasks READ tasks CONSTANT)
    Q_PROPERTY(hyps::Task *currentTask READ currentTask NOTIFY currentTaskChanged)
    Q_PROPERTY(int activeCount READ activeCount NOTIFY activeCountChanged)
    Q_PROPERTY(QVariantList recentTasks READ recentTasks NOTIFY recentTasksChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit TaskManager(AppPaths *paths, QObject *parent = nullptr);
    ~TaskManager() override;

    QAbstractItemModel *tasks() const { return m_model; }
    Task *currentTask() const { return m_currentTask; }
    int activeCount() const;
    QVariantList recentTasks() const;
    QString lastError() const { return m_lastError; }

    Task *run(const TaskSpec &spec);

    Q_INVOKABLE void select(const QString &taskId);
    Q_INVOKABLE void loadCurrentLog();
    Q_INVOKABLE void cancelTask(const QString &taskId);
    Q_INVOKABLE void cancelActive();
    Q_INVOKABLE void clearFinishedHistory();
    Q_INVOKABLE void clearCurrentLogView();

    void cancelAll();
    bool hasActiveTasks() const { return activeCount() > 0; }
    void loadLogInto(Task *task);

signals:
    void taskStarted(hyps::Task *task);
    void taskFinished(hyps::Task *task);
    void currentTaskChanged();
    void activeCountChanged();
    void recentTasksChanged();
    void lastErrorChanged();

private:
    void setCurrentTask(Task *task);
    void writeStream(Task *task, int stream, const QString &chunk);
    void flushStreams(Task *task);
    void writeMetaLine(Task *task, const QString &line);
    void finalizeTask(Task *task,
                      Task::State state,
                      int exitCode,
                      bool hasExitCode,
                      const QString &errorSummary);
    void loadHistory();
    void appendHistory(const Task &task);
    void trimHistoryFile();
    void pruneTaskLogs(int keep);
    void pruneHistoryModel();
    void removeContext(const QString &taskId);
    void setLastError(const QString &message);
    Task *taskById(const QString &taskId) const;

    AppPaths *m_paths = nullptr;
    TaskListModel *m_model = nullptr;
    Task *m_currentTask = nullptr;
    QHash<QString, TaskContext *> m_contexts;
    QString m_lastError;
    int m_sequence = 0;
};

} // namespace hyps
