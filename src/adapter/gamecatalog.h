#pragma once

#include <QAbstractListModel>
#include <QHash>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

namespace hyps {

class AppPaths;
class RuntimeManager;

/**
 * 游戏目录：从 Hyps 配置目录（CONFIG_DIR）读取已配置游戏，从 Hyps 组件的
 * games.examples 读取可添加的模板，并从 scripts/*.sh 的 GAME_NAME 发现启动脚本。
 *
 * 这里只做「配置层面的展示与校验」，真正的启动动作仍由 HypsAdapter 调用上游脚本。
 */
class GameCatalog : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ count NOTIFY changed)
    Q_PROPERTY(int configuredCount READ count NOTIFY changed)
    Q_PROPERTY(QVariantList templates READ templates NOTIFY templatesChanged)
    Q_PROPERTY(QString gamesDirectory READ gamesDirectory CONSTANT)

public:
    enum Roles {
        SlugRole = Qt::UserRole + 1,
        LabelRole,
        ExePathRole,
        RunnerNameRole,
        StatusRole,
        StatusLevelRole,
        LaunchableRole,
        LauncherPathRole,
        ExeExistsRole,
        ConfigPathRole,
    };

    explicit GameCatalog(AppPaths *paths, RuntimeManager *runtime, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return static_cast<int>(m_games.size()); }
    QVariantList templates() const { return m_templates; }
    QString gamesDirectory() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap gameBySlug(const QString &slug) const;
    Q_INVOKABLE QVariantMap templateBySlug(const QString &slug) const;
    Q_INVOKABLE int indexOfSlug(const QString &slug) const;
    Q_INVOKABLE QString labelForSlug(const QString &slug) const;
    Q_INVOKABLE QVariantList allGames() const;
    Q_INVOKABLE QString firstSlug() const;
    Q_INVOKABLE QString launcherForSlug(const QString &slug) const;

    static QString labelForSlugStatic(const QString &slug);

signals:
    void changed();
    void templatesChanged();
    void templatesRefreshed();

private:
    struct GameEntry
    {
        QString slug;
        QString label;
        QString exePath;
        QString runnerName;
        QString status;
        QString statusLevel;
        QString launcherPath;
        QString configPath;
        bool exeExists = false;
        bool launchable = false;
    };

    void scanLaunchers();
    void scanRunners();
    void buildGames();
    void buildTemplates();
    QVariantMap entryToMap(const GameEntry &entry) const;

    AppPaths *m_paths = nullptr;
    RuntimeManager *m_runtime = nullptr;
    QVector<GameEntry> m_games;
    QVariantList m_templates;
    QStringList m_runnerNames;
    QHash<QString, QString> m_launchers;
};

} // namespace hyps
