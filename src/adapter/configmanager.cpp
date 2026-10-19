#include "adapter/configmanager.h"

#include "adapter/configfile.h"
#include "app/apppaths.h"
#include "runtime/runtimemanager.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>

namespace hyps {

namespace {

bool commandAvailable(const QString &program)
{
    return !QStandardPaths::findExecutable(program).isEmpty();
}

QVariantMap field(const QString &key, const QString &title, const QString &group,
                  const QString &type, const QString &description,
                  const QString &hint = QString())
{
    QVariantMap map;
    map.insert(QStringLiteral("key"), key);
    map.insert(QStringLiteral("title"), title);
    map.insert(QStringLiteral("group"), group);
    map.insert(QStringLiteral("type"), type);
    map.insert(QStringLiteral("description"), description);
    map.insert(QStringLiteral("hint"), hint);
    return map;
}

} // namespace

ConfigManager::ConfigManager(AppPaths *paths, RuntimeManager *runtime, QObject *parent)
    : QObject(parent)
    , m_paths(paths)
    , m_runtime(runtime)
{
    setupFields();
    reloadCommon();
    reloadRunners();

    if (m_runtime) {
        connect(m_runtime, &RuntimeManager::stateChanged, this, [this]() {
            if (m_runtime->ready()) {
                reloadRunners();
            }
        });
    }
}

QString ConfigManager::commonConfigPath() const
{
    return gamesDirectory() + QStringLiteral("/_common.conf");
}

QString ConfigManager::gamesDirectory() const
{
    return m_paths->hypsConfigDir() + QStringLiteral("/games");
}

QString ConfigManager::runnerDirectory() const
{
    const QStringList candidates = {
        m_paths->hypsConfigDir() + QStringLiteral("/runners"),
        m_paths->runtimeDir() + QStringLiteral("/config/runners"),
    };
    for (const QString &candidate : candidates) {
        const QDir dir(candidate);
        if (dir.exists() && !dir.entryList({QStringLiteral("*.conf")}, QDir::Files).isEmpty()) {
            return candidate;
        }
    }
    return candidates.first();
}

bool ConfigManager::runnerDirectoryIsolated() const
{
    const QString runtimePrefix = m_paths->runtimeDir() + QLatin1Char('/');
    return !runnerDirectory().startsWith(runtimePrefix);
}

void ConfigManager::setupFields()
{
    m_commonFields = {
        field(QStringLiteral("mangohud.enabled"), QStringLiteral("MangoHud 覆盖层"),
              QStringLiteral("性能与 GameMode"), QStringLiteral("bool"),
              QStringLiteral("使用 MangoHud 显示帧率、功耗等信息（需要安装 mangohud）。")),
        field(QStringLiteral("gamemode.wrapper.enabled"), QStringLiteral("GameMode（wrapper 方式）"),
              QStringLiteral("性能与 GameMode"), QStringLiteral("bool"),
              QStringLiteral("通过 gamemoderun 包装器启用 GameMode；与 LD_PRELOAD 方式互斥。")),
        field(QStringLiteral("gamemode.ld_preload.enabled"),
              QStringLiteral("GameMode（LD_PRELOAD 方式）"),
              QStringLiteral("性能与 GameMode"), QStringLiteral("bool"),
              QStringLiteral("通过 LD_PRELOAD 加载 GameMode 库；与 wrapper 方式互斥。")),

        field(QStringLiteral("prepare.kill_wineserver"), QStringLiteral("启动前清理 wineserver"),
              QStringLiteral("运行准备"), QStringLiteral("bool"),
              QStringLiteral("启动游戏前结束残留的 wineserver 进程。")),
        field(QStringLiteral("prepare.intel_rapl_read"), QStringLiteral("Intel RAPL 能耗读取"),
              QStringLiteral("运行准备"), QStringLiteral("bool"),
              QStringLiteral("调整 Intel RAPL 读取权限，供 MangoHud 显示 CPU 功耗（可能使用 sudo）。")),
        field(QStringLiteral("taskset.enabled"), QStringLiteral("CPU 亲和性"),
              QStringLiteral("运行准备"), QStringLiteral("bool"),
              QStringLiteral("将游戏进程绑定到指定 CPU 核心（需要 taskset）。")),
        field(QStringLiteral("taskset.cpus"), QStringLiteral("CPU 列表"),
              QStringLiteral("运行准备"), QStringLiteral("array"),
              QStringLiteral("例如 [ 0-7 ] 或 [ 0, 2, 4, 6 ]。")),

        field(QStringLiteral("cache.shader.enabled"), QStringLiteral("着色器缓存目录"),
              QStringLiteral("缓存"), QStringLiteral("bool"),
              QStringLiteral("把游戏的着色器缓存保存到 Hyps 缓存目录。")),
        field(QStringLiteral("cache.dx.enabled"), QStringLiteral("DXVK/VKD3D 缓存目录"),
              QStringLiteral("缓存"), QStringLiteral("bool"),
              QStringLiteral("把 DXVK/VKD3D 缓存保存到 Hyps 缓存目录。")),

        field(QStringLiteral("overlay.enabled"), QStringLiteral("启用 OverlayFS"),
              QStringLiteral("Overlay"), QStringLiteral("bool"),
              QStringLiteral("用 FUSE OverlayFS 提供可写视图，游戏对安装目录的修改写入 upper 层（需要 fuse-overlayfs）。")),
        field(QStringLiteral("overlay.lower"), QStringLiteral("原始游戏目录（lower）"),
              QStringLiteral("Overlay"), QStringLiteral("dir"),
              QStringLiteral("包含 game.exe 的游戏安装目录，作为只读下层。")),
        field(QStringLiteral("overlay.lower_auto"), QStringLiteral("自动识别游戏目录"),
              QStringLiteral("Overlay"), QStringLiteral("bool"),
              QStringLiteral("部分游戏支持自动识别；不支持的游戏必须手动设置 lower。")),

        field(QStringLiteral("features.time_record.enabled"), QStringLiteral("记录游玩时长"),
              QStringLiteral("时长与窗口"), QStringLiteral("bool"),
              QStringLiteral("记录启动次数、总时长与最后启动时间（默认开启）。")),
        field(QStringLiteral("features.time_record.min_sec"), QStringLiteral("最短计时（秒）"),
              QStringLiteral("时长与窗口"), QStringLiteral("int"),
              QStringLiteral("短于该时长的运行不计入统计，默认 60。")),
        field(QStringLiteral("features.window_time_indicator.enabled"),
              QStringLiteral("窗口内时长提示"), QStringLiteral("时长与窗口"),
              QStringLiteral("bool"),
              QStringLiteral("在游戏窗口上显示本次/今日游玩时长（依赖 xwin-watch 窗口检测）。")),
        field(QStringLiteral("features.xwin_watch_kill.enabled"), QStringLiteral("关窗后结束游戏"),
              QStringLiteral("时长与窗口"), QStringLiteral("bool"),
              QStringLiteral("检测到游戏窗口关闭后结束相关进程（需要窗口名称或 pgrep 参数）。")),

        field(QStringLiteral("features.userdata_link.enabled"), QStringLiteral("链接用户数据"),
              QStringLiteral("用户数据"), QStringLiteral("bool"),
              QStringLiteral("把游戏用户数据链接到统一目录，便于管理（部分游戏支持）。")),
        field(QStringLiteral("features.userdata_link.screenshots"),
              QStringLiteral("截图目录"), QStringLiteral("用户数据"), QStringLiteral("dir"),
              QStringLiteral("默认 $XDG_PICTURES_DIR/HypsScreenshots，每个游戏有独立子目录。")),
        field(QStringLiteral("features.pfx_link"), QStringLiteral("创建 pfx 链接"),
              QStringLiteral("用户数据"), QStringLiteral("bool"),
              QStringLiteral("在 prefix 目录创建 pfx -> . 的链接（umu 通常已自带）。")),

        field(QStringLiteral("gamescope.enabled"), QStringLiteral("使用 Gamescope"),
              QStringLiteral("可选包装器"), QStringLiteral("bool"),
              QStringLiteral("用 gamescope 包裹游戏（需要安装 gamescope）。")),
        field(QStringLiteral("inhibit.enabled"), QStringLiteral("阻止系统休眠"),
              QStringLiteral("可选包装器"), QStringLiteral("bool"),
              QStringLiteral("游戏运行期间通过 systemd-inhibit 阻止空闲休眠。")),
        field(QStringLiteral("systemd_run.enabled"), QStringLiteral("使用 systemd-run"),
              QStringLiteral("可选包装器"), QStringLiteral("bool"),
              QStringLiteral("在独立的 systemd scope 中运行游戏。")),
        field(QStringLiteral("obs_vkcapture.wrapper.enabled"), QStringLiteral("OBS 游戏捕获"),
              QStringLiteral("可选包装器"), QStringLiteral("bool"),
              QStringLiteral("通过 obs-gamecapture 包装器启用 Vulkan 捕获。")),
        field(QStringLiteral("features.hosts_disconnect.enabled"),
              QStringLiteral("启动时临时修改 Hosts"), QStringLiteral("可选包装器"),
              QStringLiteral("bool"),
              QStringLiteral("游戏运行期间向 hosts 写入指定内容以断网启动，退出后恢复（可能使用 sudo）。")),
        field(QStringLiteral("features.ntfs_detect.enabled"), QStringLiteral("NTFS 检测"),
              QStringLiteral("可选包装器"), QStringLiteral("bool"),
              QStringLiteral("检测游戏是否位于 NTFS 分区并给出提示（默认开启）。")),

        field(QStringLiteral("env.DXVK_HUD"), QStringLiteral("DXVK HUD"),
              QStringLiteral("环境变量"), QStringLiteral("text"),
              QStringLiteral("例如 fps,frametimes,gpu,temp；留空表示不启用。")),
        field(QStringLiteral("env.PROTON_DLSS_INDICATOR"), QStringLiteral("DLSS 指示器"),
              QStringLiteral("环境变量"), QStringLiteral("bool"),
              QStringLiteral("显示 DLSS 版本/预设等信息（需要支持的 Proton）。")),
    };

    m_gameFields = {
        field(QStringLiteral("game.exe"), QStringLiteral("游戏可执行文件"),
              QStringLiteral("基础"), QStringLiteral("file"),
              QStringLiteral("Windows 游戏的 .exe 绝对路径；上游 CLI 会校验文件存在。")),
        field(QStringLiteral("runner.name"), QStringLiteral("运行器"),
              QStringLiteral("基础"), QStringLiteral("runner"),
              QStringLiteral("对应 runners/<名称>.conf；也可以在本文件直接写 runner.exe / runner.protonpath。")),
        field(QStringLiteral("game.args"), QStringLiteral("游戏参数"),
              QStringLiteral("基础"), QStringLiteral("array"),
              QStringLiteral("每行一个参数，例如 -dx12。保存时会写成多行数组。")),
        field(QStringLiteral("game.cwd"), QStringLiteral("工作目录"),
              QStringLiteral("高级"), QStringLiteral("dir"),
              QStringLiteral("默认是 game.exe 所在目录。")),
        field(QStringLiteral("game.prefix"), QStringLiteral("Wine Prefix"),
              QStringLiteral("高级"), QStringLiteral("dir"),
              QStringLiteral("默认在 DATA_DIR/prefixes/<游戏名>，一般不需要修改。")),
        field(QStringLiteral("game.umu_id"), QStringLiteral("UMU ID"),
              QStringLiteral("高级"), QStringLiteral("text"),
              QStringLiteral("少数需要父进程替身的游戏会用到，例如 umu-genshin。")),
    };
}

void ConfigManager::reloadCommon()
{
    if (!m_common) {
        m_common = new ConfigFile(commonConfigPath(), this);
    }
    m_common->load();
}

void ConfigManager::reloadAll()
{
    reloadCommon();
    for (ConfigFile *config : std::as_const(m_gameConfigs)) {
        config->load();
    }
    for (ConfigFile *config : std::as_const(m_runnerConfigs)) {
        config->load();
    }
    reloadRunners();
    emit reloaded();
}

void ConfigManager::reloadRunners()
{
    m_runnerNames.clear();
    m_runners.clear();

    const QDir dir(runnerDirectory());
    const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.conf")}, QDir::Files,
                                                  QDir::Name);
    for (const QFileInfo &file : files) {
        const QString name = file.completeBaseName();
        m_runnerNames.append(name);

        ConfigFile config(file.absoluteFilePath());
        config.load();
        const QString exe = config.valueFor(QStringLiteral("runner.exe"));
        const QString proton = config.valueFor(QStringLiteral("runner.protonpath"));

        QString status;
        QString level = QStringLiteral("ok");
        if (exe.isEmpty() && proton.isEmpty()) {
            status = tr("缺少 runner.exe / runner.protonpath");
            level = QStringLiteral("warn");
        } else if (!exe.isEmpty()) {
            const bool found = exe.contains(QLatin1Char('/'))
                    ? QFileInfo(exe).isExecutable()
                    : commandAvailable(exe);
            if (!found) {
                status = tr("找不到可执行文件：%1").arg(exe);
                level = QStringLiteral("warn");
            } else {
                status = exe;
            }
        } else {
            status = tr("Proton：%1").arg(proton);
        }

        QVariantMap map;
        map.insert(QStringLiteral("name"), name);
        map.insert(QStringLiteral("path"), file.absoluteFilePath());
        map.insert(QStringLiteral("exe"), exe);
        map.insert(QStringLiteral("protonpath"), proton);
        map.insert(QStringLiteral("status"), status);
        map.insert(QStringLiteral("statusLevel"), level);
        m_runners.append(map);
    }

    emit runnersChanged();
}

ConfigFile *ConfigManager::runnerConfig(const QString &name)
{
    static const QRegularExpression validName(QStringLiteral("^[A-Za-z0-9_.-]+$"));
    if (!validName.match(name).hasMatch()) {
        return nullptr;
    }
    if (ConfigFile *cached = m_runnerConfigs.value(name, nullptr)) {
        return cached;
    }
    auto *config = new ConfigFile(runnerDirectory() + QLatin1Char('/') + name
                                          + QStringLiteral(".conf"),
                                  this);
    config->load();
    m_runnerConfigs.insert(name, config);
    return config;
}

ConfigFile *ConfigManager::gameConfig(const QString &slug)
{
    static const QRegularExpression validSlug(QStringLiteral("^[a-z0-9_-]+$"));
    if (!validSlug.match(slug).hasMatch()) {
        return nullptr;
    }
    if (ConfigFile *cached = m_gameConfigs.value(slug, nullptr)) {
        return cached;
    }
    auto *config = new ConfigFile(gamesDirectory() + QLatin1Char('/') + slug
                                          + QStringLiteral(".conf"),
                                  this);
    config->load();
    m_gameConfigs.insert(slug, config);
    return config;
}

QVariantList ConfigManager::issue(const QString &level, const QString &key,
                                  const QString &message) const
{
    QVariantMap map;
    map.insert(QStringLiteral("level"), level);
    map.insert(QStringLiteral("key"), key);
    map.insert(QStringLiteral("message"), message);
    return {map};
}

QVariantList ConfigManager::configIssues(const ConfigFile &config) const
{
    return config.validate();
}

QVariantList ConfigManager::validateCommon()
{
    QVariantList issues = configIssues(*m_common);

    if (m_common->isTrue(QStringLiteral("gamemode.wrapper.enabled"))
        && m_common->isTrue(QStringLiteral("gamemode.ld_preload.enabled"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("gamemode"),
                        tr("gamemode.wrapper.enabled 与 gamemode.ld_preload.enabled 只能启用一个。"));
    }
    if (m_common->isTrue(QStringLiteral("mangohud.enabled"))
        && !commandAvailable(QStringLiteral("mangohud"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("mangohud.enabled"),
                        tr("已启用 MangoHud，但系统里找不到 mangohud 命令。"));
    }
    if (m_common->isTrue(QStringLiteral("taskset.enabled"))
        && !m_common->hasKey(QStringLiteral("taskset.cpus"))
        && !m_common->hasKey(QStringLiteral("taskset.mask"))
        && !m_common->hasKey(QStringLiteral("taskset.args"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("taskset.enabled"),
                        tr("已启用 taskset，但没有设置 taskset.cpus / mask / args。"));
    }
    if (m_common->isTrue(QStringLiteral("overlay.enabled"))) {
        if (!m_common->hasKey(QStringLiteral("overlay.lower"))
            && !m_common->isTrue(QStringLiteral("overlay.lower_auto"))) {
            issues += issue(QStringLiteral("warning"), QStringLiteral("overlay.enabled"),
                            tr("已启用 Overlay，但没有设置 overlay.lower，也未启用 lower_auto。"));
        }
        if (!commandAvailable(QStringLiteral("fuse-overlayfs"))) {
            issues += issue(QStringLiteral("warning"), QStringLiteral("overlay.enabled"),
                            tr("已启用 Overlay，但系统里找不到 fuse-overlayfs。"));
        }
    }
    if (m_common->isTrue(QStringLiteral("gamescope.enabled"))
        && !commandAvailable(QStringLiteral("gamescope"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("gamescope.enabled"),
                        tr("已启用 Gamescope，但系统里找不到 gamescope 命令。"));
    }
    if (m_common->isTrue(QStringLiteral("gamemode.wrapper.enabled"))
        && !commandAvailable(QStringLiteral("gamemoderun"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("gamemode.wrapper.enabled"),
                        tr("已启用 GameMode wrapper，但系统里找不到 gamemoderun。"));
    }
    if (m_common->isTrue(QStringLiteral("features.hosts_disconnect.enabled"))
        && !m_common->hasKey(QStringLiteral("features.hosts_disconnect.content"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("features.hosts_disconnect.enabled"),
                        tr("已启用 Hosts 断网，但没有设置 features.hosts_disconnect.content。"));
    }
    return issues;
}

QVariantList ConfigManager::validateGame(const QString &slug)
{
    ConfigFile *config = gameConfig(slug);
    if (!config) {
        return issue(QStringLiteral("error"), QString(), tr("非法的游戏名"));
    }

    QVariantList issues;
    if (!config->exists()) {
        issues += issue(QStringLiteral("warning"), QString(),
                        tr("游戏配置尚不存在，可先创建配置再编辑。"));
        return issues;
    }
    issues += configIssues(*config);

    const QString exe = config->valueFor(QStringLiteral("game.exe"));
    if (exe.isEmpty()) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("game.exe"),
                        tr("缺少 game.exe，启动会失败。"));
    } else if (exe.contains(QLatin1String("/path/to/"))) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("game.exe"),
                        tr("game.exe 仍是示例占位路径。"));
    } else if (!QDir::isAbsolutePath(exe)) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("game.exe"),
                        tr("game.exe 不是绝对路径，建议改成绝对路径。"));
    } else if (!QFileInfo(exe).isFile()) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("game.exe"),
                        tr("game.exe 指向的文件不存在：%1").arg(exe));
    }

    const QString runner = config->valueFor(QStringLiteral("runner.name"));
    const bool inlineRunner = config->hasKey(QStringLiteral("runner.exe"))
            || config->hasKey(QStringLiteral("runner.protonpath"));
    if (runner.isEmpty() && !inlineRunner) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("runner.name"),
                        tr("未设置 runner.name，也没有直接提供 runner.exe / runner.protonpath。"));
    } else if (!runner.isEmpty() && !runnerExists(runner) && !inlineRunner) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("runner.name"),
                        tr("运行器配置不存在：%1.conf").arg(runner));
    }

    return issues;
}

QVariantList ConfigManager::validateRunner(const QString &name)
{
    QVariantList issues;
    const QString path = runnerDirectory() + QLatin1Char('/') + name + QStringLiteral(".conf");
    if (!QFileInfo::exists(path)) {
        return issue(QStringLiteral("error"), QString(),
                     tr("运行器配置不存在：%1").arg(path));
    }
    ConfigFile config(path);
    config.load();
    issues += configIssues(config);

    const QString exe = config.valueFor(QStringLiteral("runner.exe"));
    const QString proton = config.valueFor(QStringLiteral("runner.protonpath"));
    if (exe.isEmpty() && proton.isEmpty()) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("runner.exe"),
                        tr("既没有 runner.exe 也没有 runner.protonpath。"));
    }
    if (!exe.isEmpty()) {
        const bool found = exe.contains(QLatin1Char('/')) ? QFileInfo(exe).isExecutable()
                                                          : commandAvailable(exe);
        if (!found) {
            issues += issue(QStringLiteral("warning"), QStringLiteral("runner.exe"),
                            tr("runner.exe 不可执行或不在 PATH 中：%1").arg(exe));
        }
    }
    if (!proton.isEmpty() && QDir::isAbsolutePath(proton) && !QFileInfo(proton).isDir()) {
        issues += issue(QStringLiteral("warning"), QStringLiteral("runner.protonpath"),
                        tr("runner.protonpath 指向的目录不存在：%1").arg(proton));
    }
    return issues;
}

QVariantMap ConfigManager::runnerDetails(const QString &name) const
{
    for (const QVariant &item : m_runners) {
        const QVariantMap map = item.toMap();
        if (map.value(QStringLiteral("name")).toString() == name) {
            return map;
        }
    }
    return {};
}

bool ConfigManager::runnerExists(const QString &name) const
{
    return m_runnerNames.contains(name);
}

bool ConfigManager::hasUnsavedChanges() const
{
    if (m_common && m_common->dirty()) {
        return true;
    }
    for (const ConfigFile *config : m_gameConfigs) {
        if (config && config->dirty()) {
            return true;
        }
    }
    for (const ConfigFile *config : m_runnerConfigs) {
        if (config && config->dirty()) {
            return true;
        }
    }
    return false;
}

} // namespace hyps
