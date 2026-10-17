# 阶段二 · 架构说明

## 1. 分层

```
┌─────────────────────────────────────────────────────────────┐
│ UI Layer (QML)                                              │
│  MainWindow / Onboarding / Home / Games / Tasks / Config /  │
│  Diagnostics / Settings / 通用组件（状态卡、日志视图、选路径）│
└───────────────▲─────────────────────────────────────────────┘
                │ 只读属性 + Q_INVOKABLE（无命令拼接）
┌───────────────┴─────────────────────────────────────────────┐
│ Application Layer (C++ QObjects)                            │
│  AppPaths  AppSettings  TaskManager  ThemeManager  Notifier │
│  EnvironmentReport  Diagnostics  DirectoryModel              │
└───────────────▲─────────────────────────────────────────────┘
                │
┌───────────────┴─────────────────────────────────────────────┐
│ Adapter Layer                                                │
│  HypsAdapter ──► ProcessRunner（参数数组 / 进程组 / 环境注入）│
│  ConfigFile（上游 .conf 解析/保存/备份/校验）                 │
│  GameCatalog（配置目录 + scripts/*.sh 的 GAME_NAME）          │
│  RuntimeManager ──► ProcessRunner(git)                       │
└───────────────▲─────────────────────────────────────────────┘
                │
┌───────────────┴─────────────────────────────────────────────┐
│ External                                                     │
│  独立 Hyps 组件（$XDG_DATA_HOME/hyps-hub/runtime/Hyps）   │
│  git / bash / Hyps CLI 子进程                                 │
└─────────────────────────────────────────────────────────────┘
```

UI 层不出现任何命令字符串；所有外部调用都经 `HypsAdapter` 或 `RuntimeManager`。

## 2. 目录布局（运行时）

| 路径 | 用途 |
| --- | --- |
| `${XDG_DATA_HOME:-~/.local/share}/hyps-hub/` | 应用数据根 |
| `…/hyps-hub/runtime/Hyps/` | 独立 Hyps Git Hyps 组件 |
| `…/hyps-hub/logs/` | 应用日志、`runtime.log` |
| `…/hyps-hub/logs/tasks/` | 每个任务的输出日志 |
| `…/hyps-hub/cache/` | 可重新生成的缓存 |
| `…/hyps-hub/cache/hyps/` | 作为 `CACHE_DIR` 注入给 Hyps CLI |
| `…/hyps-hub/cache/hyps-tmp/` | 作为 `TEMP_DIR` 注入给 Hyps CLI |
| `…/hyps-hub/hyps-data/` | 作为 `DATA_DIR` 注入（prefix、overlay、时长记录） |
| `…/hyps-hub/runtime-info.json` | 初始化信息、提交、更新时间 |
| `${XDG_CONFIG_HOME:-~/.config}/hyps-hub/config.json` | GUI 自身配置（主题、窗口、偏好） |
| `…/hyps-hub/hyps/` | 作为 `CONFIG_DIR` 注入（Hyps CLI 的配置文件目录） |
| `…/hyps-hub/hyps/games/*.conf` | 游戏配置 |
| `…/hyps-hub/hyps/runners/*.conf` | 运行器配置 |
| `${XDG_STATE_HOME:-~/.local/state}/hyps-hub/tasks.jsonl` | 任务历史 |
| `…/hyps-hub/env-report.json` | 最近一次环境检测结果 |
| `…/hyps-hub/update-history.jsonl` | Hyps 组件更新记录 |

设计要点：

- **Hyps 配置与 GUI 配置分离**：GUI 配置是 `config.json`，Hyps CLI 配置由 `CONFIG_DIR` 指向 `config/hyps/`。
- 通过 `CONFIG_DIR/CACHE_DIR/DATA_DIR/TEMP_DIR` 环境变量，CLI 完全不写 Hyps 组件工作区，也不与用户自己的 `~/.config/hypsc`、`~/.local/share/hypsc`、`~/.cache/hypsc`、`/tmp/hypsc` 混用。
- Hyps 组件保持 Git 干净，更新只需 ff-only 合并；配置不随更新丢失。

## 3. 启动流程

```
main()
 ├─ 解析 CLI 参数、设置应用元数据、桌面 ID
 ├─ AppPaths 解析 XDG（支持测试用环境覆盖）
 ├─ AppSettings 载入 GUI 配置；损坏时备份并回退默认
 ├─ ThemeManager 应用主题；Notifier 连接 D-Bus（可选）
 ├─ RuntimeManager.refresh()
 │    ├─ 目录缺失            → state=missing → 引导页
 │    ├─ 关键文件缺失        → state=invalid → 引导页（不覆盖）
 │    └─ 有效               → 读 commit/branch/dirty → state=ready
 ├─ EnvironmentReport 载入上次结果（不自动跑检测）
 └─ 加载 QML，进入主界面或引导页
```

首次初始化（引导页）：

1. 检查 `git`/`bash` 是否存在；`git ls-remote` 检查网络（只读，超时 20s）。
2. 创建 XDG 目录。
3. 若目标已存在：先校验，绝不覆盖；错误页提供“打开目录”“重试”。
4. 克隆到 `runtime/.Hyps.clone-<pid>-<时间戳>`，解析进度；成功后原子改名为 `Hyps`。
5. 校验关键文件；`init.sh --check` 检测依赖；`init.sh --no-game` 初始化隔离配置。
6. 写入 `runtime-info.json`；进入主界面。
7. 任何失败：仅清理本次临时目录，保留可读错误与重试入口。

## 4. Hyps Adapter 契约

| 动作 | 程序 | 参数 | 环境 | 说明 |
| --- | --- | --- | --- | --- |
| CLI 自检 | `bash` | `<runtime>/scripts/_Hyps --help` | 隔离环境 | 校验 CLI 可执行 |
| 环境检测 | `bash` | `<runtime>/init.sh --check` | 隔离环境 | 解析分组报表 |
| 初始化配置 | `bash` | `<runtime>/init.sh --no-game` | 隔离环境 | 仅写 `CONFIG_DIR` |
| 创建游戏配置 | `bash` | `<runtime>/init.sh <slug>` | 隔离环境 | 不覆盖已有配置 |
| 启动游戏 | `bash` | `<runtime>/scripts/<Game>.sh` | 隔离环境 | 工作目录 = Hyps 组件根 |
| 诊断命令 | `bash` | `<runtime>/scripts/_Hyps game list` 等 | 隔离环境 | 白名单：`game list`、`proton list`、`time list`、`--help` |

隔离环境固定注入：

```
CONFIG_DIR=<config>/hyps
CACHE_DIR=<cache>/hyps
DATA_DIR=<data>/hyps-data
TEMP_DIR=<cache>/hyps-tmp
NO_COLOR=1
```

启动脚本发现：读取 `<runtime>/scripts/*.sh`，解析其中 `GAME_NAME="<slug>"`（与上游 `init_find_launcher_script` 相同规则），不硬编码文件名。

`ProcessRunner` 约束：

- `QProcess::setProgram` + `setArguments`，永不使用 shell。
- Unix 下 `setChildProcessModifier` 调用 `setpgid(0,0)`，取消时先 `SIGTERM` 整个进程组，1.5s 后 `SIGKILL`。
- stdout/stderr 分通道增量 UTF-8 解码（`QStringDecoder`），不假设固定编码/行格式。
- 超时、启动失败、异常退出全部转成统一任务状态与人类可读错误。

## 5. RuntimeManager 状态机

```
missing ──clone──► cloning ──成功──► verifying ──通过──► ready
   ▲                  │                   │
   │                  └──失败──► error ◄──┘
   │                                ▲
invalid ◄──校验失败─── refresh ──────┘
ready ──checkForUpdates──► ready(updateAvailable)
ready ──applyUpdate──► updating ──成功──► ready
                        └──失败──► error（保留可读日志与当前提交信息）
```

更新策略（严禁破坏性操作）：

1. `git status --porcelain` 非空 → 拒绝更新并说明。
2. `git fetch --prune origin`（仅更新远程引用）。
3. 展示当前提交 / 上游提交 / 提交主题。
4. 用户确认后 `git merge --ff-only origin/<branch>`。
5. 更新前后提交写入 `update-history.jsonl` 与 `runtime.log`；校验失败给出可执行的恢复建议。
6. 不使用 `reset --hard`、`clean`、`checkout` 覆盖用户修改。

## 6. 配置管理

`ConfigFile` 忠实实现上游 `config/parse.sh` 的语法：

- 注释、空行、`[section]`、引号、行内注释、多行 `[ ]`/`( )` 数组。
- 键集合与上游一致；未识别键原样保留。
- `setValue` / `setArray` / `removeKey` 只重写目标行，其余行按原文保留（含注释与顺序）。
- 保存：先写 `.bak.<时间戳>`（存在原文件时），再用 `QSaveFile` 原子替换；最多保留 10 个备份。
- 校验：语法错误阻止保存；`game.exe` 占位/不存在、`runner.name` 无对应配置、重复键等给警告并要求确认。
- 高级模式：原始文本编辑器，应用前完整解析，失败不落盘。

可视化字段（P0）：

- 游戏：`game.exe`（文件选择）、`runner.name`（下拉，来自 `runners/*.conf`）、`game.args`（多行数组）、`game.cwd`、`game.prefix`、`game.umu_id`。
- 通用：`mangohud.enabled`、`gamemode.wrapper.enabled`、`gamemode.ld_preload.enabled`、`prepare.kill_wineserver`、`prepare.intel_rapl_read`、`cache.shader.enabled`、`cache.dx.enabled`、`taskset.enabled`/`taskset.cpus`、`features.userdata_link.enabled`、`features.time_record.enabled`、`overlay.enabled`/`overlay.lower`、`gamescope.enabled`、`inhibit.enabled`、`env.PROTON_DLSS_INDICATOR` 等。
- 每个字段支持“恢复默认（删除该键）”；未知键折叠在高级编辑器中。

## 7. 任务与日志

- `Task`：id、kind、label、命令预览、开始/结束时间、状态（running/succeeded/failed/canceled/timeout）、退出码、错误摘要、日志路径、日志模型。
- 实时日志：`LogModel` 保存结构化行（流、序号、文本），支持过滤、复制、清空视图、上限截断。
- 落盘：每个任务一个日志文件（含元数据头与 `[out]/[err]` 前缀），任务历史 `tasks.jsonl`（最多 200 条）。
- 退出：`aboutToQuit` 与窗口关闭确认均调用取消（进程组终止），最多等待 3 秒。

## 8. 诊断

`Diagnostics` 导出目录 `hyps-hub-diagnostics-<时间戳>/`：

- `summary.txt`：应用/Qt/内核/发行版/路径/Hyps 组件提交/依赖统计/GUI 前置条件。
- `env-report.txt`、`runtime-info.json`、`config.json`（GUI 配置）。
- `task-history.jsonl`（最近 50 条）、`logs/`（最近任务日志尾部）。
- `README.txt`：内容与隐私说明。
- 对 `token/password/secret/api_key/auth` 等字段值脱敏。

## 9. 测试策略

| 层 | 方式 |
| --- | --- |
| AppPaths | 注入环境映射，验证 XDG 解析与覆盖 |
| ConfigFile | 上游示例配置作为 fixture：解析、往返、编辑、备份、损坏输入 |
| EnvironmentReport | 真实 `init --check` 输出 + ANSI/异常变体 |
| ProcessRunner | 临时 bash 脚本：stdout/stderr、退出码、超时、取消、路径空格、非 UTF-8 |
| HypsAdapter | 假 Hyps 组件（bash 脚本模拟 CLI），校验参数数组、环境注入、启动脚本发现、错误路径 |
| RuntimeManager | 注入假 `git`：成功克隆、失败清理、已存在目标不覆盖、脏工作区拒绝更新、ff-only 更新 |
| UI | `--smoke-test` 在 offscreen + software 后端加载全部 QML；`ctest` 验证退出码 |
| 网络 | `HYPS_HUB_RUN_NETWORK_TESTS=1` 时执行真实克隆 + 环境检测 + CLI 调用（手动/CI 可选） |

## 10. 明确不做

- 不实现游戏库扫描、自动下载/安装游戏或 Proton、多运行环境模板（上游没有对应能力）。
- 不提供任意命令执行器；仅白名单诊断命令。
- 不提供“使用 `~/Hyps` 作为 Hyps 组件”的隐式行为（未来可由用户显式选择，本期不做）。
- 不实现 Flatpak/AppImage（沙箱对宿主机游戏运行环境有实际限制，不做未验证的交付）。
