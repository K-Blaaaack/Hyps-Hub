# 阶段五 · 验证记录

> 环境：Arch Linux（rolling）、Qt 6.12.0、GCC 16.2.1、Ninja、Wayland/niri 会话（UI 验证使用
> `QT_QPA_PLATFORM=offscreen` + 软件渲染后端）。
> 当前版本：**0.4.0**（上游 Hyps 基线 `a2ac842`，见 [upstream-sync-2026-10-27.md](upstream-sync-2026-10-27.md)）。
> 交付提交：见 `git log -1`；本文记录的是实际执行结果，新增项在构建验证后补填。
> 完整变更记录见 [CHANGELOG.md](../CHANGELOG.md)。

## 0.4.0 · MD3 界面重写（2026-10-31 实测）

界面按 MD3 全量重写，新增自动化界面自检。上游契约未变，配置与任务历史无破坏性变更。

| 项目 | 结果 |
| --- | --- |
| 构建 | `cmake -B build -G Ninja && cmake --build build` 通过，Qt 6.12.0 + Ninja |
| 版本号 | `hyps-hub --version` 输出 `hyps-hub 0.4.0` |
| 单元测试 | `ctest` **11/11 通过**（`tst_network_e2e` 需外网，默认禁用） |
| 界面几何审计 | `scripts/ui-audit.sh` **PASS**：8 页面 × 2 尺寸（1440×900 / 1040×720），`collapsed=0 overflow=0 clipped=0 nan=0` |
| 运行时警告 | 7 个页面逐页离屏渲染，stderr **零警告** |
| QML 门禁 | `scripts/qml-check.sh` 覆盖全部页面与 46 个组件，qmllint + 离屏加载 + 零 stderr 全通过 |
| 截图 | `docs/screenshots/` 10 张，1440×900，由 `scripts/ui-fixture.sh` 隔离夹具渲染 |

审计口径：`collapsed` = 显式高度被压到 0 的可见控件；`overflow` = 子项超出父容器；
`clipped` = 文本被裁切；`nan` = 坐标或尺寸出现 NaN/Inf。


## 1. 工作区与受保护目录

- 开发目录：`/home/kb/github/Hyps-Hub`（独立仓库）。
- `~/Hyps` 全程只读：未执行 `fetch/pull/reset/clean/checkout`，未写入任何文件；
  验证结束时 `git -C ~/Hyps status --porcelain` 为空。
- 所有 CLI 行为调研均在 `.research/` 的独立克隆中完成，未使用用户配置。

## 2. 构建与自动化测试

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

结果：**11/11 通过**（0.3.0 实测：`ctest --test-dir build --output-on-failure`，2026-10-27；`tst_network_e2e` 默认禁用）：

| 测试 | 覆盖 | 结果 |
| --- | --- | --- |
| `tst_apppaths` | XDG 解析、隔离环境变量、目录清单 | PASS |
| `tst_configfile` | 上游 `.conf` 语法、编辑保留注释、备份、原始文本、重复键 | PASS |
| `tst_environmentreport` | 真实 `init.sh --check` 报表、ANSI、持久化 | PASS |
| `tst_processrunner` | stdout/stderr、退出码、取消（进程组）、超时、路径空格、非 UTF-8、参数不经 shell | PASS |
| `tst_runtimemanager` | 克隆成功/失败清理、目标存在不覆盖、网络检查、脏工作区拒绝更新、ff-only 更新、合并失败 | PASS |
| `tst_hypsadapter` | 假组件：参数、隔离环境、启动脚本发现、环境检测、白名单 | PASS |
| `tst_gamecatalog` | 已配置游戏、模板、缺失 exe/启动脚本状态 | PASS |
| `tst_diagnostics` | 诊断包结构、密钥/Authorization/URL 凭据脱敏、大日志尾部导出 | PASS |
| `tst_taskmanager` | 历史日志懒加载、大日志尾部、清空历史删除任务日志 | PASS |
| `tst_configmanager` | 连字符 slug、未保存配置检测；0.3.0 新增 15 个用例见下 | PASS（0.3.0：19 passed / 0 failed） |
| `tst_smoke` | 真实进程加载全部 QML 后退出 | PASS |

### 0.3.0 新增用例（已实测）

0.3.0 适配上游 `a2ac842`，`tst_configmanager` 新增 15 个用例（另有 2 个原有用例）。
实测：`./build/tests/tst_configmanager` → **19 passed / 0 failed / 0 skipped**（2026-10-27）。

| 用例 | 覆盖 | 结果 |
| --- | --- | --- |
| `commonFieldsDropHostsDisconnect` | 通用字段目录不再包含 `features.hosts_disconnect.enabled` | PASS |
| `gameFieldsForEndfieldAppendsSurrogateCatalog` | `gameFieldsFor("endfield")` 追加「终末地替身」11 个字段，`mode` 为 `enum` 且带 `options` | PASS |
| `gameFieldsForOtherGamesKeepsBaseCatalog` | 其他游戏只返回基础字段 | PASS |
| `reportsHostsDisconnectResidualKeys` | 残留 `features.hosts_disconnect.*` 键 → warning | PASS |
| `acceptsCommonWithoutHostsKeys` | 无残留键时 `validateCommon()` 不产生 hosts 相关告警 | PASS |
| `endfieldSurrogateModeMissing` | 存在其他替身键但 `mode` 为空 → error | PASS |
| `endfieldSurrogateModeInvalid` | `mode` 不在 `launcher`/`hardlink`/`copy`/`hardlink-or-copy` → error | PASS |
| `endfieldSurrogateDisabledIsClean` | 只有空 `mode`（未启用）→ 无 error | PASS |
| `endfieldSurrogateDirTargetConflict` | 同前缀 `dir` 与 `target` 同时存在 → error | PASS |
| `endfieldSurrogateHardlinkAndCopyConflicts` | `hardlink_`/`copy_` 前缀的 `dir`+`target` 冲突 → error | PASS |
| `endfieldLauncherModeRequiresLauncher` | `mode = launcher` 缺 `launcher` → error | PASS |
| `endfieldLauncherModeRejectsSourceKeys` | `mode = launcher` 同时存在源目录/文件键 → error | PASS |
| `endfieldExitAfterMustBePositiveInteger` | `exit_after` 非正整数 → error | PASS |
| `endfieldSurrogateKeysIgnoredForOtherGames` | 非 `endfield` 游戏不校验替身键 | PASS |
| `warnsAboutRemovedFpsUnlockProg` | 存在 `gi.fps_unlock.prog` → warning（不阻止保存） | PASS |

### 真实网络端到端测试

```bash
HYPS_HUB_RUN_NETWORK_TESTS=1 TMPDIR=$PWD/build/tests/tmp ./build/tests/tst_network_e2e
```

实际结果（3 passed）：

- 从 `https://github.com/MoYingJi/Hyps.git` 克隆到临时 XDG 目录，提交 `72191b2`
  （`fix: 修正 runner 配置检查，允许省略 runner.exe`）。
- 执行 `init.sh --no-game`，`CONFIG_DIR` 下生成 `_common.conf` 与运行器配置；
  Hyps 组件 `config/games/_common.conf` 不存在（证明隔离生效）。
- 执行真实 `init.sh --check`：**必需项 10/10 通过，可选能力缺失 3 项，配置待创建 1 项**。
- 执行真实 `scripts/_Hyps --help`：成功且输出包含子命令 `game`。
- `runtime-info.json` 写入 `initializedAt`。
- 测试使用临时目录，不触碰 `~/Hyps` 与真实 `~/.config/hypsc`。

## 3. 界面验证

通过 `--screenshot` 在 1440×900、深色主题下渲染真实数据：

- `docs/screenshots/onboarding.png`：首次初始化向导（前置检查、进度、按钮、实时日志）。
- `docs/screenshots/home.png`：真实环境报表、组件提交、CLI 自检、最近任务、快捷操作。
- `docs/screenshots/games.png`：已配置游戏、示例路径警告、`game.exe`/`runner.name`/`game.args` 编辑、
  高级参数、原始编辑器入口。
- `docs/screenshots/about.png`：独立关于页（构建/系统/组件/许可/数据位置）。
- `docs/screenshots/add-game.png`：从上游示例模板创建游戏配置（隔离 CONFIG_DIR，不覆盖已有配置）。
- `docs/screenshots/tasks.png`：任务列表、实时日志与退出码。
- `docs/screenshots/config.png`：通用配置分组、开关与保存流程。
- `docs/screenshots/diagnostics.png`：前置检查、环境报表、更新与诊断命令。
- `docs/screenshots/settings.png`：主题、通知、组件与隐私设置。
- `docs/screenshots/editor.png`：大窗口原始配置编辑器（双向滚动、Ctrl+S、应用/保存）。

QML 加载无警告（`tst_smoke`、截图运行均无 QML 警告）。设计规范中的 0 圆角、45° 切角、单强边、
微标签、噪点/网格/警戒线纹理、44px 主按钮均已落地；未使用任何鹰角专有美术资产。

## 4. 安装与打包

### CMake 本地安装

```bash
cmake --install build --prefix "$PWD/build/prefix"
```

安装内容：

```
bin/hyps-hub
share/applications/hyps-hub.desktop
share/icons/hicolor/scalable/apps/hyps-hub.svg
share/doc/hyps-hub/{README,install,troubleshooting,development,architecture,research,upstream-sync-2026-10-27,design,credits}.md
share/licenses/hyps-hub/GPL-3.0-only.txt
```

`desktop-file-validate` 仅提示 Categories 建议（已改为单一 `Game;`）。
版本号来自 CMake 的 `project(HypsHub VERSION ...)`，0.3.0 构建后二进制以 `--version` 输出
`hyps-hub 0.3.0`（0.2.0 实测输出为 `hyps-hub 0.2.0`）。

### Arch PKGBUILD

```bash
git archive --prefix=hyps-hub-0.3.0/ -o hyps-hub-0.3.0.tar.gz HEAD
makepkg -f
```

0.2.0 实测：`hyps-hub 0.2.0-1 (x86_64)` 构建成功，包大小约 378 KiB（安装后约 832 KiB）。
0.3.0 实测（2026-10-27，本机 `makepkg -f`）：`hyps-hub 0.3.0-1 (x86_64)` 构建成功，包大小约 399 KiB（`size = 907170`，安装后约 886 KiB），`.PKGINFO` 的 `pkgver` 为 `0.3.0-1`。
包内容包含可执行文件、desktop、图标、文档、许可证；无安装脚本，不写系统级用户配置。
从包中解出的二进制在独立 XDG 目录下可正常执行 `--version`，`ldd` 无缺失库。

## 5. 功能验收映射

| 验收条件 | 结果 |
| --- | --- |
| 应用可构建、启动 | 是（CTest + 截图 + 安装后二进制） |
| 首次使用初始化独立 Hyps 组件 | 是（真实网络测试） |
| 初始化后检测 CLI 并执行真实核心任务 | 是（真实 `init.sh --check`、`_Hyps --help`） |
| 不依赖修改 `~/Hyps` | 是（全程只读，状态干净） |
| CLI 调用全部经过适配层 | 是（`HypsAdapter` / `RuntimeManager`，QML 无命令） |
| 错误处理、日志、配置、更新策略 | 是（单元测试 + 界面） |
| Arch 打包经过实际验证 | 是（makepkg 成功，检查包内容） |
| 上游 0.3.0 契约同步（hosts 移除、替身字段、弃用键） | 已实现，随 0.3.0 验证（字段目录 + 语义校验用例） |
| 未实现功能/已知问题如实记录 | 见 README「已知限制」与下文 |

## 6. 未覆盖与已知限制

- **真实游戏启动未执行**：本机没有已安装的上游支持游戏；启动路径通过假组件验证了参数、环境、
  启动脚本发现与退出码，不冒充真实游戏运行结果。
- **终末地替身未做真实运行验证**：0.3.0 只验证字段目录与语义校验（模式冲突、目标互斥、`exit_after`），
  未实际生成替身文件或挂起官方启动器。
- **hosts 断网已随上游移除**：`a2ac842` 删除该功能，0.3.0 只保留残留键告警，未验证旧配置迁移（因为不做迁移）。
- **交互流程未做自动化点击测试**：按钮/对话框通过 QML 冒烟加载与截图验证，未做 GUI 自动化。
- **Wayland 实际窗口行为**：截图使用 offscreen；Qt Wayland 路径未在真实合成器上做窗口状态恢复验证。
- **桌面通知**：D-Bus 接口已实现并在无服务时静默降级，未在真实通知守护进程上验证。
- 上游表格输出（`game list` 等）只作为诊断原始输出展示，不作为 GUI 主数据源。
- 更新只支持快进合并；脏工作区拒绝更新，需用户手动处理。
- 未实现 P1/P2 的配置导入/导出、多运行环境模板、游戏库扫描等。

## 7. 复现命令

```bash
# 单元测试
./scripts/build.sh

# 真实网络测试
HYPS_HUB_RUN_NETWORK_TESTS=1 TMPDIR=$PWD/build/tests/tmp ./build/tests/tst_network_e2e

# 本地安装
./scripts/install-local.sh

# QML 冒烟
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./build/hyps-hub --smoke-test
```
