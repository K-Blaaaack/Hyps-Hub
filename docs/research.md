# 阶段一 · 技术调研报告

> 调研时间：基于本机 `~/Hyps`（上游 fork，分支 `fix/init-runner-check`，提交 `72191b2`）以及上游 `https://github.com/MoYingJi/Hyps.git` 的 `main` 分支（调研时同为 `72191b2`）。
> 调研方式：只读阅读源码与文档；不修改 `~/Hyps`。所有命令行为均在 `.research/` 下的独立克隆中验证。

## 1. 工作区与环境检查

| 项目 | 结果 |
| --- | --- |
| 当前工作目录 | `/home/kb/github/Hyps-Hub`（空目录，**不是** Git 仓库） |
| 受保护目录 `~/Hyps` | 存在，Git 工作区干净，分支 `fix/init-runner-check`，无未提交修改 |
| `~/Hyps` remote | `origin` → `https://github.com/MoYingJi/Hyps.git`；`fork` → `https://github.com/K-Blaaaack/Hyps.git` |
| 操作约束 | 全程只读；未执行 `pull/fetch/reset/clean`，未生成任何文件 |
| 发行版 | Arch Linux (rolling) |
| 图形会话 | Wayland / niri（`XDG_SESSION_TYPE=wayland`） |
| Qt | Qt 6.12.0（qt6-base、qt6-declarative、qt6-svg 已安装；Qt Quick Controls 2 的 Basic/Fusion 样式可用） |
| 工具链 | cmake、ninja、gcc、git、python3、bash 均可用 |
| 运行依赖现状 | `umu-run`、`mangohud`、`gamemoderun` 可用；`wine` 可用；`column`（util-linux）可用；无 `mingw-w64`、无 `fuse-overlayfs` |
| XDG | 全部未显式设置（按默认 `~/.local/share`、`~/.config`、`~/.local/state`、`~/.cache` 解析） |
| 网络 | 可访问 GitHub（`git ls-remote` 成功） |

结论：`~/Hyps` 是用户正在使用的工作目录，**不能**作为 GUI 的数据目录、配置目录或 Hyps 组件。GUI 必须建立独立目录（本仓库 `/home/kb/github/Hyps-Hub`），并在运行时把独立组件克隆到 XDG 数据目录。

## 2. 上游实际结构

Hyps 是一个 **Bash 脚本集合**（62 个 `.sh`、20 个 `.conf`、11 个 C 工具、3 个 Python 工具），不是编译型程序：

```
init.sh                   # 入口: 等价于 scripts/_Hyps init
config.conf               # 仓库级配置: path.config = "./config"
scripts/_Hyps             # 工具入口，dispatch 到 lib/commands/*.sh
scripts/<Game>.sh         # 每个游戏一个启动脚本，内容为 GAME_NAME="<slug>" + source lib/common.sh + hyps_main
lib/libs.sh               # 公共库加载入口
lib/core/{console,log,lifecycle}.sh
lib/config.sh             # 配置加载/合并/校验
lib/config/{parse,using,environment}.sh
lib/commands/{_dispatch,game,init,proton,shader_cache,time}.sh
lib/init/{check,setup}.sh # 环境检测与配置脚手架
lib/features/*.sh         # 16 个可选功能（overlay、hosts、缓存、时间记录等）
lib/games/*.sh            # 7 个游戏实现
lib/utils/*.sh            # 工具函数
tools/*                   # C/Python 小工具（fpsunlock、xwin-watch、补丁等）
config/games.examples/    # 示例配置（模板）
config/runners/           # 运行器配置模板（umu-*）
```

### 2.1 实际支持的 CLI 能力（以源码为准）

| 命令 | 说明 | 输出 | 可机器解析 |
| --- | --- | --- | --- |
| `./init.sh --check` | 环境检测，不写文件 | 分组报表（`[✓]/[!]/[✗]/[i]`）+ 必需项统计 | **是**，适合 GUI 解析 |
| `./init.sh --list` | 示例配置与当前状态 | 表格 | 半结构化 |
| `./init.sh --no-game` | 初始化基础配置（目录、`_common.conf`、runners） | 过程日志 | 否，但退出码可靠 |
| `./init.sh <game>` | 初始化基础配置并复制指定游戏示例配置（不覆盖已有） | 过程日志 | 否 |
| `./init.sh --force <game>` | 覆盖前备份为 `.bak.<时间戳>` | 过程日志 | 否 |
| `./scripts/_Hyps --help` | 列出子命令 | `game/init/proton/shader-cache/time` | 是（简单列表） |
| `./scripts/_Hyps game list` | 已配置游戏状态 | `column -t` 表格 | 半结构化（路径含空格时列会错位） |
| `./scripts/_Hyps proton list` | 检测到的 Proton | `column -t` 两列表格 | 半结构化 |
| `./scripts/_Hyps time list/today/report` | 游玩时间记录 | 表格/键值 | 半结构化 |
| `./scripts/_Hyps shader-cache invalidate <game>` | 清理着色器缓存 | 交互确认（需要 stdin） | 否 |
| `./scripts/<Game>.sh` | **启动游戏**（真实核心动作） | 日志输出，退出码透传 | 否，但过程可实时采集 |

关键事实：

- 没有 `game start` 之类的启动子命令；**启动游戏的唯一真实入口**是 `scripts/<Game>.sh`，脚本内部读取 `GAME_NAME`。
- 没有 JSON/YAML 等机器接口；`init --check` 是唯一结构稳定、适合解析的人类可读输出。
- 颜色仅在 **stderr 是 TTY** 时输出（`use_color()` 检查 `-t 2`），GUI 以管道方式运行时输出纯文本；仍会加入 `NO_COLOR=1` 双保险。
- 日志（`[时间] [级别] [模块] 消息`）走 stderr；业务数据走 stdout。适配层必须分通道采集。
- 退出码：`die 1/2/4`，命令分发失败为 1，`init --check` 在必需项缺失时返回非 0。
- 禁止以 root 运行（`common.sh` 与 `_Hyps` 均检查 `$UID`）。
- 依赖：bash >= 4.3、coreutils、grep/sed/awk、pkill/pgrep、sha256sum/md5sum、`umu-run`（必需）、`column`（建议）、gcc/python3/mingw-w64/sudo（可选能力）。
- 上游文档明确表示“只是启动脚本，远达不到启动器”，**没有游戏库扫描、自动下载/安装/更新能力**；GUI 不得虚构这些能力。

### 2.2 配置格式（`lib/config/parse.sh`）

- 行式 INI 风格：`key = value`；`#` 开头为注释；行内注释（引号外）被剥离；支持 `[section]` 前缀。
- 值可为单/双引号字符串、裸值、多行数组 `[ ... ]` 或 `( ... )`；数组元素按逗号/空格解析。
- 同一键多次出现时后者覆盖前者；`runner.name` 指向 `config/runners/<name>.conf`，游戏配置优先级高于 runner 配置。
- `_common.conf` 先加载，再加载游戏配置；`runner.exe` 可省略，由 `runner.protonpath` 推导 `<proton>/proton`。
- 游戏配置默认位置：仓库 `config.conf` 中 `path.config`（上游默认 `./config`），可被环境变量 `CONFIG_DIR` 覆盖。
- 缓存/数据/临时目录同理可被 `CACHE_DIR`、`DATA_DIR`、`TEMP_DIR` 覆盖（`config_read_realpath_prefer_env` 先在环境变量中取非空值）。
- 已确认全部键名（用于 GUI 可视化编辑），例如 `game.exe`、`game.args`、`game.cwd`、`game.prefix`、`game.umu_id`、`runner.name`、`runner.exe`、`runner.args`、`runner.protonpath`、`mangohud.*`、`gamemode.*`、`taskset.*`、`cache.*`、`features.*`、`overlay.*`、`env.*`、`nvapi.drs.settings`、`starrail.reg_fps.*`、`gi.fps_unlock.*` 等。

### 2.3 隔离机制（重要发现）

上游 `lib/config.sh` 使用：

```bash
config_read_realpath_prefer_env path.config CONFIG_DIR "${XDG_CONFIG_HOME:-$HOME/.config}/hypsc"
config_read_realpath_prefer_env path.cache  CACHE_DIR  "${XDG_CACHE_HOME:-$HOME/.cache}/hypsc"
config_read_realpath_prefer_env path.data   DATA_DIR   "${XDG_DATA_HOME:-$HOME/.local/share}/hypsc"
config_read_realpath_prefer_env path.temp   TEMP_DIR   "/tmp/hypsc"
```

`config_read_realpath_prefer_env` 在目标变量**已非空**时直接采用该值。因此 GUI 在启动 CLI 子进程时显式传入
`CONFIG_DIR` / `CACHE_DIR` / `DATA_DIR` / `TEMP_DIR`，即可把 Hyps 的配置、缓存、prefix/overlay、临时目录全部隔离到
`hyps-hub` 自己的 XDG 目录，**且完全不写入独立 Hyps 组件的 Git 工作区**（保持工作区干净，便于安全更新）。
这是上游源码支持的稳定行为，写在适配层中作为兼容契约。

## 3. 技术选型记录

### 3.1 候选方案对比

| 维度 | Qt 6 + QML（选用） | GTK 4 + Libadwaita | 其他（Electron/Tauri 等） |
| --- | --- | --- | --- |
| 本机可用性 | Qt 6.12 已安装，CMake/Ninja 成熟 | 需确认 libadwaita 开发包 | 需大量额外运行时 |
| Wayland | Qt 6 原生支持，niri/Wayland 实测可用 | 原生支持 | Web 技术栈在 Wayland 下依赖运行时 |
| 子进程管理 | `QProcess` 成熟，支持独立进程组、分通道、环境注入 | `GSubprocess` 可用 | 依赖 Node/Rust 生态 |
| 依赖体积 | qt6-base/declarative/svg | GTK 4 + libadwaita | Electron 体积大 |
| Arch 打包 | 官方仓库齐备，PKGBUILD 简单 | 官方仓库齐备 | 需 vendored 运行时 |
| 可测试性 | Qt Test + CTest + offscreen 平台，适配层可注入 | GLib Test | 参差 |
| 长期维护 | 稳定、文档完善 | 稳定 | 版本更新快 |

### 3.2 决策

采用 **C++20 + Qt 6（Qt Quick / QML + Qt Quick Controls 2，Basic 样式自定义主题）**：

- 使用 `QProcess` 以**参数数组**启动子进程，绝不经过 shell；为每个子进程建立独立进程组，取消时按进程组终止，避免游戏/`umu-run` 残留。
- QML 只做展示与交互，所有命令、配置读写、Git 操作都在 C++ 层（Adapter / RuntimeManager / Configuration Manager）。
- 不依赖 KDE Frameworks / Kirigami，保证 GNOME、KDE、niri 等环境行为一致；主题跟随系统 `QStyleHints::colorScheme`，支持手动切换。
- 单二进制 `hyps-hub`，资源内置，安装只需可执行文件 + desktop + 图标。

### 3.3 版本兼容策略

- 适配层只依赖已确认的上游契约：`init.sh`、`scripts/_Hyps`、`scripts/<Game>.sh`、`config.conf` 的 `path.config`、四个 XDG 覆盖环境变量、配置格式。
- 对表格类输出（`game list` / `proton list`）不做强依赖；GUI 的游戏列表来自读取配置目录（配置管理层职责），启动仍调用上游脚本。
- 上游重构出现破坏性变更时，只需更新 Adapter 内的路径/命令封装，并保留清晰的错误提示（CLI 版本/提交、原始输出、诊断导出）。

## 4. 功能映射表

| 需求 | 上游真实能力 | GUI 实现方式 | 阶段 |
| --- | --- | --- | --- |
| 首次初始化自动克隆 | Git 仓库 | RuntimeManager 用 `git clone --progress` 克隆到 XDG 数据目录；临时目录 + 原子改名；失败清理本次临时目录 | P0 |
| 初始化进度 | Git 进度输出 | 解析 `Receiving objects: N%` 等 stderr，异步不冻结 UI | P0 |
| 环境/依赖检测 | `init.sh --check` | Adapter 调用并解析分组报表，展示必需项/可选项/配置项 | P0 |
| 初始化配置 | `init.sh --no-game` | Adapter 调用（注入隔离的 `CONFIG_DIR` 等） | P0 |
| 游戏列表 | 配置文件 + `scripts/<Game>.sh` | GameCatalog 读取 `config/games/*.conf`、示例模板与启动脚本的 `GAME_NAME` | P0 |
| 游戏启动 | `scripts/<Game>.sh` | Adapter 以隔离环境启动，实时日志、退出码、取消（进程组） | P0 |
| 启动参数配置 | `game.args` 等配置键 | 游戏配置可视化编辑（含 `game.args` 多行数组），保存前校验与备份 | P0 |
| 运行器配置 | `config/runners/*.conf` | Runner 列表 + 原始编辑器 | P0 |
| 通用配置 | `_common.conf` | 常用开关（MangoHud/GameMode/缓存/taskset/overlay 等）+ 原始编辑器 | P0 |
| CLI 版本/提交 | Git 信息 | RuntimeManager 读 `git rev-parse`/`git log`/`git status` | P0 |
| 任务与日志 | 进程输出 | TaskManager + LogModel：实时 stdout/stderr、搜索、复制、清空、取消、历史、退出码 | P0 |
| 诊断导出 | 日志/配置/检测结果 | Diagnostics 导出诊断目录（已脱敏） | P0 |
| 手动更新 | Git | 检查 `git fetch` + 展示差异；更新仅 `git merge --ff-only`，脏工作区拒绝，记录前后提交 | P0/P1 |
| 通知、窗口状态、快捷键 | — | D-Bus 通知、窗口几何恢复、快捷键 | P1 |
| 游戏库扫描/自动安装/多环境 | 上游不支持 | **不实现**，界面不提供假入口 | P2/明确不做 |

## 5. 安全边界

1. 永不写入 `~/Hyps`：GUI 所有数据位于 `$XDG_DATA_HOME/hyps-hub`、`$XDG_CONFIG_HOME/hyps-hub`、`$XDG_STATE_HOME/hyps-hub`。
2. 调用 CLI 时注入 `CONFIG_DIR/CACHE_DIR/DATA_DIR/TEMP_DIR` 覆盖，使 CLI 不触碰 `~/.config/hypsc`、`~/.local/share/hypsc`、`~/.cache/hypsc`、`/tmp/hypsc`，也不在 Hyps 组件内生成配置。
3. 克隆目标若已存在：先校验，不覆盖；克隆失败仅删除本次创建的临时目录。
4. 更新仅在 Git 工作区干净时执行 `fetch` + `merge --ff-only`；禁止 `reset --hard`、`clean`。
5. 所有子进程调用使用参数数组，不使用 `sh -c`；不以 root 运行（检测到 root 时界面明确警告且上游 CLI 自身也会拒绝）。
6. 日志与诊断导出对疑似密钥字段做脱敏。

## 6. 已知限制

- 游戏启动的真实性取决于用户是否安装游戏与 Proton/umu 环境；GUI 不提供任何模拟数据。
- 上游 `game list` 等表格输出列宽不稳定，GUI 不将其作为主数据源。
- 上游没有“更新 Hyps 组件”命令，GUI 用 Git 实现，并保持为可回退的安全操作（ff-only）。
- 沙箱打包（Flatpak 等）会限制宿主机游戏与 GPU 访问，因此本次只交付原生 PKGBUILD，不虚构沙箱可用性。
