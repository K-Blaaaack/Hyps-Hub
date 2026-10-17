#pragma once

#include <QObject>
#include <QProcessEnvironment>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace hyps {

class AppPaths;
class EnvironmentReport;
class RuntimeManager;
class Task;
class TaskManager;

/**
 * Hyps CLI 适配层：所有对上游的调用都集中在这里。
 *
 * 约束：
 *  - 使用参数数组调用 bash + 脚本，绝不经过 shell；
 *  - 注入隔离后的 CONFIG_DIR / CACHE_DIR / DATA_DIR / TEMP_DIR；
 *  - 启动脚本通过扫描 scripts/*.sh 的 GAME_NAME 发现，不硬编码文件名；
 *  - 诊断命令使用白名单，不提供任意命令执行器。
 */
class HypsAdapter : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool canRun READ canRun NOTIFY canRunChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QVariantList diagnosticActions READ diagnosticActions CONSTANT)
    Q_PROPERTY(QString cliEntryPoint READ cliEntryPoint CONSTANT)
    Q_PROPERTY(bool cliVerified READ cliVerified NOTIFY cliVerifiedChanged)

public:
    HypsAdapter(AppPaths *paths, RuntimeManager *runtime, TaskManager *tasks,
                EnvironmentReport *report, QObject *parent = nullptr);

    bool canRun() const;
    QString lastError() const { return m_lastError; }
    QVariantList diagnosticActions() const;
    QString cliEntryPoint() const;
    bool cliVerified() const { return m_cliVerified; }

    Q_INVOKABLE hyps::Task *checkEnvironment();
    Q_INVOKABLE hyps::Task *initializeConfig();
    Q_INVOKABLE hyps::Task *createGameConfig(const QString &slug);
    Q_INVOKABLE hyps::Task *launchGame(const QString &slug, const QString &label);
    Q_INVOKABLE hyps::Task *verifyCli();
    Q_INVOKABLE hyps::Task *runDiagnostic(const QString &actionId);
    Q_INVOKABLE QVariantMap canLaunch(const QString &slug) const;
    Q_INVOKABLE QString launcherForSlug(const QString &slug) const;

signals:
    void canRunChanged();
    void lastErrorChanged();
    void environmentChecked();
    void configInitialized();
    void gameConfigCreated(const QString &slug);
    void cliVerifiedChanged();

private:
    Task *runCli(const QString &kind, const QString &label, const QStringList &scriptArguments,
                 int timeoutMs, bool probe, const QString &detail = QString());
    QProcessEnvironment cliEnvironment(bool *ok);
    QString findLauncherScript(const QString &slug) const;
    void setLastError(const QString &message);
    bool runtimeUsable(QString *reason) const;

    AppPaths *m_paths = nullptr;
    RuntimeManager *m_runtime = nullptr;
    TaskManager *m_tasks = nullptr;
    EnvironmentReport *m_report = nullptr;
    QString m_lastError;
    bool m_cliVerified = false;
};

} // namespace hyps
