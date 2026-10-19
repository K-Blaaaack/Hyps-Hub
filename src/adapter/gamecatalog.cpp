#include "adapter/gamecatalog.h"

#include "adapter/configfile.h"
#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTextStream>

namespace hyps {

namespace {

const QHash<QString, QString> &gameLabels()
{
    static const QHash<QString, QString> labels = {
        {QStringLiteral("starrail"), QStringLiteral("崩坏：星穹铁道")},
        {QStringLiteral("yuanshen"), QStringLiteral("原神")},
        {QStringLiteral("zenless"), QStringLiteral("绝区零")},
        {QStringLiteral("honkai3"), QStringLiteral("崩坏三")},
        {QStringLiteral("wuwa"), QStringLiteral("鸣潮")},
        {QStringLiteral("arknights"), QStringLiteral("明日方舟")},
        {QStringLiteral("endfield"), QStringLiteral("明日方舟：终末地")},
    };
    return labels;
}

} // namespace

GameCatalog::GameCatalog(AppPaths *paths, RuntimeManager *runtime, QObject *parent)
    : QAbstractListModel(parent)
    , m_paths(paths)
    , m_runtime(runtime)
{
    if (m_runtime) {
        connect(m_runtime, &RuntimeManager::stateChanged, this, [this]() { refresh(); });
    }
    refresh();
}

int GameCatalog::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_games.size());
}

QVariant GameCatalog::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_games.size()) {
        return {};
    }
    const GameEntry &entry = m_games.at(index.row());
    switch (role) {
    case SlugRole:
        return entry.slug;
    case LabelRole:
        return entry.label;
    case ExePathRole:
        return entry.exePath;
    case RunnerNameRole:
        return entry.runnerName;
    case StatusRole:
        return entry.status;
    case StatusLevelRole:
        return entry.statusLevel;
    case LaunchableRole:
        return entry.launchable;
    case LauncherPathRole:
        return entry.launcherPath;
    case ExeExistsRole:
        return entry.exeExists;
    case ConfigPathRole:
        return entry.configPath;
    default:
        return {};
    }
}

QHash<int, QByteArray> GameCatalog::roleNames() const
{
    return {
        {SlugRole, QByteArrayLiteral("slug")},
        {LabelRole, QByteArrayLiteral("label")},
        {ExePathRole, QByteArrayLiteral("exePath")},
        {RunnerNameRole, QByteArrayLiteral("runnerName")},
        {StatusRole, QByteArrayLiteral("status")},
        {StatusLevelRole, QByteArrayLiteral("statusLevel")},
        {LaunchableRole, QByteArrayLiteral("launchable")},
        {LauncherPathRole, QByteArrayLiteral("launcherPath")},
        {ExeExistsRole, QByteArrayLiteral("exeExists")},
        {ConfigPathRole, QByteArrayLiteral("configPath")},
    };
}

QString GameCatalog::gamesDirectory() const
{
    return m_paths->hypsConfigDir() + QStringLiteral("/games");
}

QString GameCatalog::labelForSlugStatic(const QString &slug)
{
    return gameLabels().value(slug, slug);
}

QString GameCatalog::labelForSlug(const QString &slug) const
{
    return labelForSlugStatic(slug);
}

void GameCatalog::scanRunners()
{
    m_runnerNames.clear();
    const QStringList directories = {
        m_paths->hypsConfigDir() + QStringLiteral("/runners"),
        m_paths->runtimeDir() + QStringLiteral("/config/runners"),
    };
    for (const QString &directory : directories) {
        QDir dir(directory);
        if (!dir.exists()) {
            continue;
        }
        const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.conf")}, QDir::Files,
                                                      QDir::Name);
        for (const QFileInfo &file : files) {
            const QString name = file.completeBaseName();
            if (!name.isEmpty() && !m_runnerNames.contains(name)) {
                m_runnerNames.append(name);
            }
        }
        if (!m_runnerNames.isEmpty()) {
            break;
        }
    }
}

void GameCatalog::scanLaunchers()
{
    m_launchers.clear();
    const QDir scriptsDir(m_paths->launcherScriptsDir());
    if (!scriptsDir.exists()) {
        return;
    }
    const QFileInfoList scripts = scriptsDir.entryInfoList(
            {QStringLiteral("*.sh")}, QDir::Files | QDir::Readable, QDir::Name);
    static const QRegularExpression nameRe(
            QStringLiteral("^\\s*GAME_NAME=\"?([^\"\\s]+)\"?\\s*$"),
            QRegularExpression::MultilineOption);

    for (const QFileInfo &script : scripts) {
        if (script.fileName().startsWith(QLatin1Char('_'))) {
            continue;
        }
        QFile file(script.absoluteFilePath());
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }
        const QString content = QString::fromUtf8(file.read(8192));
        const auto match = nameRe.match(content);
        if (!match.hasMatch()) {
            continue;
        }
        const QString slug = match.captured(1).trimmed();
        if (!slug.isEmpty() && !m_launchers.contains(slug)) {
            m_launchers.insert(slug, script.absoluteFilePath());
        }
    }
}

void GameCatalog::buildGames()
{
    m_games.clear();
    const QDir gamesDir(gamesDirectory());
    if (!gamesDir.exists()) {
        return;
    }

    const QFileInfoList files = gamesDir.entryInfoList({QStringLiteral("*.conf")}, QDir::Files,
                                                       QDir::Name);
    static const QRegularExpression validSlug(QStringLiteral("^[a-z0-9_-]+$"));
    for (const QFileInfo &file : files) {
        const QString slug = file.completeBaseName();
        if (slug == QLatin1String("_common") || slug.isEmpty()
            || !validSlug.match(slug).hasMatch()) {
            continue;
        }

        GameEntry entry;
        entry.slug = slug;
        entry.label = labelForSlugStatic(slug);
        entry.configPath = file.absoluteFilePath();

        ConfigFile config(file.absoluteFilePath());
        config.load();
        entry.exePath = config.valueFor(QStringLiteral("game.exe"));
        entry.runnerName = config.valueFor(QStringLiteral("runner.name"));
        entry.launcherPath = m_launchers.value(slug);
        entry.exeExists = !entry.exePath.isEmpty() && QFileInfo(entry.exePath).isFile();

        const bool inlineRunner = config.hasKey(QStringLiteral("runner.exe"))
                || config.hasKey(QStringLiteral("runner.protonpath"));

        QString status;
        QString level;
        if (entry.exePath.isEmpty()) {
            status = tr("缺少 game.exe");
            level = QStringLiteral("warn");
        } else if (entry.exePath.contains(QLatin1String("/path/to/"))) {
            status = tr("示例路径未修改");
            level = QStringLiteral("warn");
        } else if (!QDir::isAbsolutePath(entry.exePath)) {
            status = tr("建议使用绝对路径");
            level = QStringLiteral("warn");
        } else if (!entry.exeExists) {
            status = tr("game.exe 不存在");
            level = QStringLiteral("warn");
        }

        if (entry.runnerName.isEmpty()) {
            if (!inlineRunner) {
                status = tr("缺少 runner.name");
                level = QStringLiteral("warn");
            }
        } else if (!m_runnerNames.contains(entry.runnerName) && !inlineRunner) {
            status = tr("未知运行器：%1").arg(entry.runnerName);
            level = QStringLiteral("warn");
        }

        if (entry.launcherPath.isEmpty()) {
            status = tr("缺少启动脚本");
            level = QStringLiteral("error");
        }

        if (status.isEmpty()) {
            status = tr("就绪");
            level = QStringLiteral("ok");
            entry.launchable = true;
        }

        entry.status = status;
        entry.statusLevel = level;
        m_games.append(entry);
    }
}

void GameCatalog::buildTemplates()
{
    m_templates.clear();
    const QDir examplesDir(m_paths->runtimeDir() + QStringLiteral("/config/games.examples"));
    if (!examplesDir.exists()) {
        emit templatesChanged();
        return;
    }

    const QFileInfoList files =
            examplesDir.entryInfoList({QStringLiteral("*.example.conf")}, QDir::Files, QDir::Name);
    for (const QFileInfo &file : files) {
        QString slug = file.fileName();
        slug.remove(QStringLiteral(".example.conf"));
        if (slug.isEmpty() || slug == QLatin1String("_common")) {
            continue;
        }
        QVariantMap map;
        map.insert(QStringLiteral("slug"), slug);
        map.insert(QStringLiteral("label"), labelForSlugStatic(slug));
        map.insert(QStringLiteral("configured"),
                   QFileInfo(gamesDirectory() + QLatin1Char('/') + slug
                             + QStringLiteral(".conf"))
                           .exists());
        map.insert(QStringLiteral("examplePath"), file.absoluteFilePath());
        m_templates.append(map);
    }
    emit templatesChanged();
}

void GameCatalog::refresh()
{
    beginResetModel();
    scanRunners();
    scanLaunchers();
    buildGames();
    endResetModel();
    buildTemplates();
    emit changed();
    emit templatesRefreshed();
}

QVariantMap GameCatalog::gameBySlug(const QString &slug) const
{
    for (const GameEntry &entry : m_games) {
        if (entry.slug == slug) {
            return entryToMap(entry);
        }
    }
    return {};
}

QVariantMap GameCatalog::entryToMap(const GameEntry &entry) const
{
    QVariantMap map;
    map.insert(QStringLiteral("slug"), entry.slug);
    map.insert(QStringLiteral("label"), entry.label);
    map.insert(QStringLiteral("exePath"), entry.exePath);
    map.insert(QStringLiteral("runnerName"), entry.runnerName);
    map.insert(QStringLiteral("status"), entry.status);
    map.insert(QStringLiteral("statusLevel"), entry.statusLevel);
    map.insert(QStringLiteral("launchable"), entry.launchable);
    map.insert(QStringLiteral("launcherPath"), entry.launcherPath);
    map.insert(QStringLiteral("exeExists"), entry.exeExists);
    map.insert(QStringLiteral("configPath"), entry.configPath);
    return map;
}

QVariantMap GameCatalog::templateBySlug(const QString &slug) const
{
    for (const QVariant &item : m_templates) {
        const QVariantMap map = item.toMap();
        if (map.value(QStringLiteral("slug")).toString() == slug) {
            return map;
        }
    }
    return {};
}

int GameCatalog::indexOfSlug(const QString &slug) const
{
    for (int i = 0; i < m_games.size(); ++i) {
        if (m_games.at(i).slug == slug) {
            return i;
        }
    }
    return -1;
}

QString GameCatalog::launcherForSlug(const QString &slug) const
{
    return m_launchers.value(slug);
}

QVariantList GameCatalog::allGames() const
{
    QVariantList list;
    list.reserve(m_games.size());
    for (const GameEntry &entry : m_games) {
        list.append(entryToMap(entry));
    }
    return list;
}

QString GameCatalog::firstSlug() const
{
    return m_games.isEmpty() ? QString() : m_games.first().slug;
}

} // namespace hyps
