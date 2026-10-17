#pragma once

#include <QObject>
#include <QProcessEnvironment>
#include <QString>
#include <QStringList>
#include <QVariantList>

namespace hyps {

/**
 * XDG 路径解析与应用环境信息。
 *
 * 所有路径都在构造时一次性解析，之后不可变。遵循 XDG Base Directory 规范：
 * 环境变量为空或不是绝对路径时回退到默认值。
 *
 * 测试与开发可以用 HYPS_HUB_DATA_DIR / HYPS_HUB_CONFIG_DIR / HYPS_HUB_STATE_DIR
 * 覆盖根目录（必须是绝对路径）。
 */
class AppPaths : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)
    Q_PROPERTY(QString configDir READ configDir CONSTANT)
    Q_PROPERTY(QString stateDir READ stateDir CONSTANT)
    Q_PROPERTY(QString cacheDir READ cacheDir CONSTANT)
    Q_PROPERTY(QString logsDir READ logsDir CONSTANT)
    Q_PROPERTY(QString tasksLogDir READ tasksLogDir CONSTANT)
    Q_PROPERTY(QString runtimeRoot READ runtimeRoot CONSTANT)
    Q_PROPERTY(QString runtimeDir READ runtimeDir CONSTANT)
    Q_PROPERTY(QString hypsConfigDir READ hypsConfigDir CONSTANT)
    Q_PROPERTY(QString hypsCacheDir READ hypsCacheDir CONSTANT)
    Q_PROPERTY(QString hypsDataDir READ hypsDataDir CONSTANT)
    Q_PROPERTY(QString hypsTempDir READ hypsTempDir CONSTANT)
    Q_PROPERTY(QString guiConfigFile READ guiConfigFile CONSTANT)
    Q_PROPERTY(QString runtimeInfoFile READ runtimeInfoFile CONSTANT)
    Q_PROPERTY(QString taskHistoryFile READ taskHistoryFile CONSTANT)
    Q_PROPERTY(QString envReportFile READ envReportFile CONSTANT)
    Q_PROPERTY(QString updateHistoryFile READ updateHistoryFile CONSTANT)
    Q_PROPERTY(QString runtimeLogFile READ runtimeLogFile CONSTANT)
    Q_PROPERTY(QString cliEntryPoint READ cliEntryPoint CONSTANT)
    Q_PROPERTY(QString initScript READ initScript CONSTANT)

    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(QString gitCommit READ gitCommit CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString osPrettyName READ osPrettyName CONSTANT)
    Q_PROPERTY(QString sessionType READ sessionType CONSTANT)
    Q_PROPERTY(QString desktopName READ desktopName CONSTANT)
    Q_PROPERTY(bool runningAsRoot READ runningAsRoot CONSTANT)
    Q_PROPERTY(bool wayland READ wayland CONSTANT)
    Q_PROPERTY(QString monoFontFamily READ monoFontFamily CONSTANT)
    Q_PROPERTY(QString uiFontFamily READ uiFontFamily CONSTANT)
    Q_PROPERTY(QString displayFontFamily READ displayFontFamily CONSTANT)
    Q_PROPERTY(QVariantList directories READ directories CONSTANT)

public:
    explicit AppPaths(const QProcessEnvironment &environment, QObject *parent = nullptr);
    explicit AppPaths(QObject *parent = nullptr);

    QString dataDir() const { return m_dataDir; }
    QString configDir() const { return m_configDir; }
    QString stateDir() const { return m_stateDir; }
    QString cacheDir() const { return m_cacheDir; }
    QString logsDir() const { return m_logsDir; }
    QString tasksLogDir() const { return m_tasksLogDir; }
    QString runtimeRoot() const { return m_runtimeRoot; }
    QString runtimeDir() const { return m_runtimeDir; }
    QString hypsConfigDir() const { return m_hypsConfigDir; }
    QString hypsCacheDir() const { return m_hypsCacheDir; }
    QString hypsDataDir() const { return m_hypsDataDir; }
    QString hypsTempDir() const { return m_hypsTempDir; }
    QString guiConfigFile() const { return m_configDir + QStringLiteral("/config.json"); }
    QString runtimeInfoFile() const { return m_dataDir + QStringLiteral("/runtime-info.json"); }
    QString taskHistoryFile() const { return m_stateDir + QStringLiteral("/tasks.jsonl"); }
    QString envReportFile() const { return m_stateDir + QStringLiteral("/env-report.json"); }
    QString updateHistoryFile() const { return m_stateDir + QStringLiteral("/update-history.jsonl"); }
    QString runtimeLogFile() const { return m_logsDir + QStringLiteral("/runtime.log"); }

    QString appVersion() const { return m_appVersion; }
    QString gitCommit() const { return m_gitCommit; }
    QString qtVersion() const { return m_qtVersion; }
    QString kernelVersion() const { return m_kernelVersion; }
    QString osPrettyName() const { return m_osPrettyName; }
    QString sessionType() const { return m_sessionType; }
    QString desktopName() const { return m_desktopName; }
    bool runningAsRoot() const;
    bool wayland() const { return m_wayland; }
    QString monoFontFamily() const { return m_monoFontFamily; }
    QString uiFontFamily() const { return m_uiFontFamily; }
    QString displayFontFamily() const { return m_displayFontFamily; }
    QVariantList directories() const;

    /** 创建所有应用目录；失败时返回 false 并写入 error。 */
    bool ensureBaseDirectories(QString *error = nullptr) const;

    /**
     * 构造调用 Hyps CLI 的环境：继承当前环境，并注入隔离的
     * CONFIG_DIR / CACHE_DIR / DATA_DIR / TEMP_DIR 与 NO_COLOR。
     *
     * 这与上游 lib/config.sh 的 `config_read_realpath_prefer_env` 契约一致：
     * 非空的环境变量优先于配置文件与默认值。
     */
    QProcessEnvironment hypsEnvironment() const;

    /** CLI Hyps 组件的入口脚本路径。 */
    QString cliEntryPoint() const { return m_runtimeDir + QStringLiteral("/scripts/_Hyps"); }
    QString initScript() const { return m_runtimeDir + QStringLiteral("/init.sh"); }
    QString launcherScriptsDir() const { return m_runtimeDir + QStringLiteral("/scripts"); }

    static QString resolveXdgDir(const QProcessEnvironment &environment,
                                 const QString &variable,
                                 const QString &homeFallback);
    static QString normalizeAbsolute(const QString &path);

private:
    void resolve(const QProcessEnvironment &environment);
    void resolvePlatformInfo(const QProcessEnvironment &environment);

    QString m_dataDir;
    QString m_configDir;
    QString m_stateDir;
    QString m_cacheDir;
    QString m_logsDir;
    QString m_tasksLogDir;
    QString m_runtimeRoot;
    QString m_runtimeDir;
    QString m_hypsConfigDir;
    QString m_hypsCacheDir;
    QString m_hypsDataDir;
    QString m_hypsTempDir;

    QString m_appVersion;
    QString m_gitCommit;
    QString m_qtVersion;
    QString m_kernelVersion;
    QString m_osPrettyName;
    QString m_sessionType;
    QString m_desktopName;
    QString m_monoFontFamily;
    QString m_uiFontFamily;
    QString m_displayFontFamily;
    QProcessEnvironment m_environment;
    bool m_wayland = false;
};

} // namespace hyps
