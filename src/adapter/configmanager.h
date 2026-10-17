#pragma once

#include <QHash>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace hyps {

class AppPaths;
class ConfigFile;
class RuntimeManager;

/**
 * 配置管理层：持有 GUI 编辑用的配置文档，提供字段定义、运行器目录与语义校验。
 *
 * 编辑对象位于注入给 CLI 的 CONFIG_DIR（$XDG_CONFIG_HOME/hyps-hub/hyps），
 * 不会写入 Hyps 组件工作区，也不会写入用户自己的 ~/.config/hypsc。
 */
class ConfigManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(hyps::ConfigFile *common READ common CONSTANT)
    Q_PROPERTY(QVariantList commonFields READ commonFields CONSTANT)
    Q_PROPERTY(QVariantList gameFields READ gameFields CONSTANT)
    Q_PROPERTY(QStringList runnerNames READ runnerNames NOTIFY runnersChanged)
    Q_PROPERTY(QVariantList runners READ runners NOTIFY runnersChanged)
    Q_PROPERTY(QString runnerDirectory READ runnerDirectory NOTIFY runnersChanged)
    Q_PROPERTY(bool runnerDirectoryIsolated READ runnerDirectoryIsolated NOTIFY runnersChanged)
    Q_PROPERTY(QString commonConfigPath READ commonConfigPath CONSTANT)
    Q_PROPERTY(QString gamesDirectory READ gamesDirectory CONSTANT)

public:
    explicit ConfigManager(AppPaths *paths, RuntimeManager *runtime, QObject *parent = nullptr);

    ConfigFile *common() const { return m_common; }
    QVariantList commonFields() const { return m_commonFields; }
    QVariantList gameFields() const { return m_gameFields; }
    QStringList runnerNames() const { return m_runnerNames; }
    QVariantList runners() const { return m_runners; }
    QString runnerDirectory() const;
    bool runnerDirectoryIsolated() const;
    QString commonConfigPath() const;
    QString gamesDirectory() const;

    Q_INVOKABLE hyps::ConfigFile *gameConfig(const QString &slug);
    Q_INVOKABLE hyps::ConfigFile *runnerConfig(const QString &name);
    Q_INVOKABLE void reloadAll();
    Q_INVOKABLE void reloadRunners();
    Q_INVOKABLE QVariantList validateCommon();
    Q_INVOKABLE QVariantList validateGame(const QString &slug);
    Q_INVOKABLE QVariantList validateRunner(const QString &name);
    Q_INVOKABLE QVariantMap runnerDetails(const QString &name) const;
    Q_INVOKABLE bool runnerExists(const QString &name) const;

signals:
    void runnersChanged();
    void reloaded();

private:
    void setupFields();
    void reloadCommon();
    QVariantList issue(const QString &level, const QString &key, const QString &message) const;
    QVariantList configIssues(const ConfigFile &config) const;

    AppPaths *m_paths = nullptr;
    RuntimeManager *m_runtime = nullptr;
    ConfigFile *m_common = nullptr;
    QHash<QString, ConfigFile *> m_gameConfigs;
    QHash<QString, ConfigFile *> m_runnerConfigs;
    QVariantList m_commonFields;
    QVariantList m_gameFields;
    QStringList m_runnerNames;
    QVariantList m_runners;
};

} // namespace hyps
