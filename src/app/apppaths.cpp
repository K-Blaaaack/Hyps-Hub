#include "app/apppaths.h"

#include "version.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QSysInfo>
#include <QTextStream>
#include <QtGlobal>

#include <unistd.h>

namespace hyps {

namespace {

QString readOsPrettyName()
{
    QFile file(QStringLiteral("/etc/os-release"));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(file.readAll());
        static const QRegularExpression re(QStringLiteral("^PRETTY_NAME=\"?([^\"]*)\"?$"),
                                           QRegularExpression::MultilineOption);
        const auto match = re.match(content);
        if (match.hasMatch()) {
            const QString name = match.captured(1).trimmed();
            if (!name.isEmpty()) {
                return name;
            }
        }
    }
    const QString pretty = QSysInfo::prettyProductName();
    return pretty.isEmpty() ? QSysInfo::productType() : pretty;
}

} // namespace

AppPaths::AppPaths(QObject *parent)
    : AppPaths(QProcessEnvironment::systemEnvironment(), parent)
{
}

AppPaths::AppPaths(const QProcessEnvironment &environment, QObject *parent)
    : QObject(parent)
{
    resolve(environment);
    resolvePlatformInfo(environment);
}

QString AppPaths::normalizeAbsolute(const QString &path)
{
    QString clean = QDir::cleanPath(path);
    if (clean.isEmpty()) {
        return clean;
    }
    if (clean.size() > 1 && clean.endsWith(QLatin1Char('/'))) {
        clean.chop(1);
    }
    return clean;
}

QString AppPaths::resolveXdgDir(const QProcessEnvironment &environment,
                                const QString &variable,
                                const QString &homeFallback)
{
    const QString value = environment.value(variable);
    if (!value.isEmpty() && QDir::isAbsolutePath(value)) {
        return normalizeAbsolute(value);
    }

    QString home = environment.value(QStringLiteral("HOME"));
    if (home.isEmpty() || !QDir::isAbsolutePath(home)) {
        home = QDir::homePath();
    }
    return normalizeAbsolute(home + QLatin1Char('/') + homeFallback);
}

void AppPaths::resolve(const QProcessEnvironment &environment)
{
    m_environment = environment;

    const QString dataHome = resolveXdgDir(environment, QStringLiteral("XDG_DATA_HOME"),
                                           QStringLiteral(".local/share"));
    const QString configHome = resolveXdgDir(environment, QStringLiteral("XDG_CONFIG_HOME"),
                                             QStringLiteral(".config"));
    const QString stateHome = resolveXdgDir(environment, QStringLiteral("XDG_STATE_HOME"),
                                            QStringLiteral(".local/state"));

    auto overriddenRoot = [&environment](const QString &variable, const QString &fallback) {
        const QString value = environment.value(variable);
        if (!value.isEmpty() && QDir::isAbsolutePath(value)) {
            return normalizeAbsolute(value);
        }
        return fallback;
    };

    m_dataDir = overriddenRoot(QStringLiteral("HYPS_HUB_DATA_DIR"),
                               dataHome + QStringLiteral("/hyps-hub"));
    m_configDir = overriddenRoot(QStringLiteral("HYPS_HUB_CONFIG_DIR"),
                                 configHome + QStringLiteral("/hyps-hub"));
    m_stateDir = overriddenRoot(QStringLiteral("HYPS_HUB_STATE_DIR"),
                                stateHome + QStringLiteral("/hyps-hub"));

    m_cacheDir = m_dataDir + QStringLiteral("/cache");
    m_logsDir = m_dataDir + QStringLiteral("/logs");
    m_tasksLogDir = m_logsDir + QStringLiteral("/tasks");
    m_runtimeRoot = m_dataDir + QStringLiteral("/runtime");
    m_runtimeDir = m_runtimeRoot + QStringLiteral("/Hyps");

    // 注入给 Hyps CLI 的隔离目录。
    m_hypsConfigDir = m_configDir + QStringLiteral("/hyps");
    m_hypsCacheDir = m_cacheDir + QStringLiteral("/hyps");
    m_hypsDataDir = m_dataDir + QStringLiteral("/hyps-data");
    m_hypsTempDir = m_cacheDir + QStringLiteral("/hyps-tmp");
}

void AppPaths::resolvePlatformInfo(const QProcessEnvironment &environment)
{
    m_appVersion = QStringLiteral(HYPS_HUB_VERSION);
    m_gitCommit = QStringLiteral(HYPS_HUB_GIT_COMMIT);
    m_qtVersion = QString::fromLatin1(qVersion());
    m_kernelVersion = QSysInfo::kernelType() + QLatin1Char(' ') + QSysInfo::kernelVersion();
    m_osPrettyName = readOsPrettyName();
    m_sessionType = environment.value(QStringLiteral("XDG_SESSION_TYPE"));
    if (m_sessionType.isEmpty()) {
        m_sessionType = environment.contains(QStringLiteral("WAYLAND_DISPLAY"))
                ? QStringLiteral("wayland")
                : (environment.contains(QStringLiteral("DISPLAY")) ? QStringLiteral("x11")
                                                                   : QStringLiteral("unknown"));
    }
    m_desktopName = environment.value(QStringLiteral("XDG_CURRENT_DESKTOP"));
    if (m_desktopName.isEmpty()) {
        m_desktopName = environment.value(QStringLiteral("DESKTOP_SESSION"));
    }
    m_wayland = !environment.value(QStringLiteral("WAYLAND_DISPLAY")).isEmpty()
            || m_sessionType.compare(QStringLiteral("wayland"), Qt::CaseInsensitive) == 0;

    if (qobject_cast<QGuiApplication *>(QCoreApplication::instance()) != nullptr) {
        m_uiFontFamily = QGuiApplication::font().family();
        m_monoFontFamily = QFontDatabase::systemFont(QFontDatabase::FixedFont).family();

        const QStringList families = QFontDatabase::families();
        const QStringList displayCandidates = {
            QStringLiteral("Arial Narrow"),
            QStringLiteral("Roboto Condensed"),
            QStringLiteral("DIN Condensed"),
            QStringLiteral("Bebas Neue"),
            QStringLiteral("DejaVu Sans Condensed"),
        };
        for (const QString &candidate : displayCandidates) {
            if (families.contains(candidate)) {
                m_displayFontFamily = candidate;
                break;
            }
        }
    }
    if (m_uiFontFamily.isEmpty()) {
        m_uiFontFamily = QStringLiteral("Sans Serif");
    }
    if (m_monoFontFamily.isEmpty()) {
        m_monoFontFamily = QStringLiteral("Monospace");
    }
    if (m_displayFontFamily.isEmpty()) {
        m_displayFontFamily = m_uiFontFamily;
    }
}

bool AppPaths::runningAsRoot() const
{
    return ::geteuid() == 0;
}

QVariantList AppPaths::directories() const
{
    auto entry = [](const QString &name, const QString &description, const QString &path) {
        QVariantMap map;
        map.insert(QStringLiteral("name"), name);
        map.insert(QStringLiteral("description"), description);
        map.insert(QStringLiteral("path"), path);
        return map;
    };

    QVariantList list;
    list << entry(QStringLiteral("应用数据"), QStringLiteral("Hyps 组件、日志与缓存"),
                  m_dataDir)
         << entry(QStringLiteral("Hyps 组件"), QStringLiteral("独立的 Hyps Git 仓库"),
                  m_runtimeDir)
         << entry(QStringLiteral("GUI 配置"), QStringLiteral("Hyps Hub 自身配置"),
                  m_configDir)
         << entry(QStringLiteral("Hyps 配置"), QStringLiteral("注入给 CLI 的 CONFIG_DIR"),
                  m_hypsConfigDir)
         << entry(QStringLiteral("Hyps 缓存"), QStringLiteral("注入给 CLI 的 CACHE_DIR"),
                  m_hypsCacheDir)
         << entry(QStringLiteral("Hyps 数据"), QStringLiteral("注入给 CLI 的 DATA_DIR（prefix/overlay）"),
                  m_hypsDataDir)
         << entry(QStringLiteral("Hyps 临时目录"), QStringLiteral("注入给 CLI 的 TEMP_DIR"),
                  m_hypsTempDir)
         << entry(QStringLiteral("运行状态"), QStringLiteral("任务历史、环境检测结果"),
                  m_stateDir)
         << entry(QStringLiteral("日志"), QStringLiteral("应用与任务日志"), m_logsDir);
    return list;
}

bool AppPaths::ensureBaseDirectories(QString *error) const
{
    const QStringList dirs = {
        m_dataDir,      m_configDir,  m_stateDir,   m_logsDir,   m_tasksLogDir,
        m_cacheDir,     m_runtimeRoot, m_hypsConfigDir, m_hypsCacheDir, m_hypsDataDir,
        m_hypsTempDir,
    };

    for (const QString &dir : dirs) {
        if (!QDir().mkpath(dir)) {
            if (error) {
                *error = QStringLiteral("无法创建目录：%1").arg(dir);
            }
            return false;
        }
    }
    return true;
}

QProcessEnvironment AppPaths::hypsEnvironment() const
{
    QProcessEnvironment environment = m_environment;
    environment.insert(QStringLiteral("CONFIG_DIR"), m_hypsConfigDir);
    environment.insert(QStringLiteral("CACHE_DIR"), m_hypsCacheDir);
    environment.insert(QStringLiteral("DATA_DIR"), m_hypsDataDir);
    environment.insert(QStringLiteral("TEMP_DIR"), m_hypsTempDir);
    environment.insert(QStringLiteral("NO_COLOR"), QStringLiteral("1"));
    environment.insert(QStringLiteral("HYPS_HUB"), QStringLiteral("1"));
    return environment;
}

} // namespace hyps
