# 开发说明

## 1. 技术栈

- C++20 + Qt 6（Core / Gui / Quick / Qml / QuickControls2 / Svg / DBus）
- CMake + Ninja
- Qt Test + CTest（QML 冒烟测试使用 `offscreen` + `software` 后端）
- 界面为 QML，全部业务逻辑在 C++；QML 不拼接命令、不直接调用外部程序。

## 2. 目录

```
src/
  main.cpp                     组装对象、注册 QML 单例、加载界面
  app/                         GUI 应用层
    apppaths.*                 XDG 解析、CLI 隔离环境、平台信息
    appsettings.*              GUI JSON 配置（损坏自动备份并回退）
    thememanager.*             MD3 语义色板（浅/深两套）、跟随系统
    logmodel.*                 结构化日志模型 + 过滤代理
    task.*                     任务状态
    taskmanager.*              子进程任务、实时日志、历史、取消
    appcontroller.*            退出、剪贴板、打开目录/URL
    notifier.*                 D-Bus 桌面通知（可选）
    directorymodel.*           内置文件选择器模型
  adapter/
    processrunner.*            QProcess 封装：参数数组、进程组、超时
    environmentreport.*        init.sh --check 报表解析/持久化
    configfile.*               上游 .conf 语法解析、编辑、备份、校验
    configmanager.*            通用/游戏/运行器配置与语义校验
    gamecatalog.*              配置目录 + scripts/*.sh 的 GAME_NAME 发现
    hypsadapter.*              唯一的上游 CLI 调用入口
  runtime/
    runtimemanager.*           克隆、校验、Git 信息、安全更新
  diagnostics/
    diagnostics.*              脱敏诊断包导出
qml/                           MD3 界面：theme/ 令牌、components/ 组件、pages/ 页面（见 docs/design/）
tests/                         Qt Test 与假 Hyps 组件/假 git
packaging/                    PKGBUILD、desktop
scripts/                      构建、运行、本地安装/卸载
```

## 3. 适配层契约（重要）

| 动作 | 程序 | 参数 | 说明 |
| --- | --- | --- | --- |
| 环境检测 | `bash` | `<runtime>/init.sh --check` | 解析 stdout 报表 |
| 初始化配置 | `bash` | `<runtime>/init.sh --no-game` | 只写隔离 `CONFIG_DIR` |
| 创建游戏配置 | `bash` | `<runtime>/init.sh <slug>` | 不覆盖已有配置 |
| CLI 自检 | `bash` | `<runtime>/scripts/_Hyps --help` | 只读 |
| 启动游戏 | `bash` | `<runtime>/scripts/<Game>.sh` | 工作目录为 Hyps 组件根 |
| 更新 | `git` | `-C <runtime> fetch --prune origin` / `merge --ff-only` | 不 reset/clean |

所有 CLI 调用都注入：

```
CONFIG_DIR=<config>/hyps
CACHE_DIR=<cache>/hyps
DATA_DIR=<data>/hyps-data
TEMP_DIR=<cache>/hyps-tmp
NO_COLOR=1
```

这是上游 `lib/config.sh` 的 `config_read_realpath_prefer_env` 所支持的行为。**不要**去掉这些变量，
否则 CLI 会写入共享的 `~/.config/hypsc` 等目录。

新增上游调用时：

1. 先确认上游源码/文档中的真实参数与退出码；
2. 在 `HypsAdapter` 内构造参数数组，不经过 shell；
3. 若命令只用于诊断，加入 `diagnosticActions()` 白名单；
4. 为参数/输出解析补测试（假 Hyps 组件即可）。

## 4. 测试

```bash
cmake -S . -B build -G Ninja -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

- `tst_configfile`：上游 `.conf` 语法（注释、引号、数组、section、备份、原始文本）
- `tst_environmentreport`：真实 `init.sh --check` 输出与 ANSI/异常变体
- `tst_processrunner`：stdout/stderr、退出码、超时、取消（进程组）、路径空格、非 UTF-8
- `tst_runtimemanager`：用 `tests/fixtures/fake-git.sh` 模拟克隆/失败/脏工作区/更新
- `tst_hypsadapter`：假 Hyps 组件验证参数、隔离环境、启动脚本发现、白名单
- `tst_gamecatalog`、`tst_apppaths`、`tst_diagnostics`
- `tst_smoke`：以真实进程加载 QML 后退出

真实网络测试（克隆 GitHub、真实 `init.sh --check`）：

```bash
HYPS_HUB_RUN_NETWORK_TESTS=1 TMPDIR=$PWD/build/tests/tmp ./build/tests/tst_network_e2e
```

该测试会使用独立的临时 XDG 目录，不会触碰 `~/Hyps`。

## 5. 调试

- `scripts/dev-run.sh`：**开发模式**，`--qml-source` 从磁盘加载 QML，改界面不用重新编译。
  监视 `qml/` 自动重启（600ms 去抖），监视 `src/`、`CMakeLists.txt` 变动时先增量编译再重启；
  编译或加载失败时保留旧进程，错误写 `/tmp/hyps-dev.log`。
  - `scripts/dev-run.sh` 前台运行（Ctrl-C 退出）、`--bg` 后台、`--stop` 停止、`--once` 只启动一次。
- `--smoke-test`：加载 QML 后 1.5s 退出，用于检查 QML 错误。
- `--screenshot <path>`：加载后保存窗口截图（需要 `QT_QPA_PLATFORM=offscreen` 或真实会话）。
- `--preview-dialog <objectName>`：加载后自动打开指定 QML 弹窗，用于截图/调试；例如
  `--preview-dialog addGameDialog --screenshot add-game.png`。
- `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software`：无显示环境下的 QML 验证。
- `scripts/ui-audit.sh`：全页几何审计（`COLLAPSED`/`OVERFLOW`/`CLIPPED`/`NAN`）
  + 逐页运行时警告门禁，两种窗口尺寸各跑一遍；合入前必须 `PASS`。
- 日志：`~/.local/share/hyps-hub/logs/`；任务日志在 `logs/tasks/`。
- Hyps 组件日志：`logs/runtime.log`；更新记录：`~/.local/state/hyps-hub/update-history.jsonl`。
- ⚠️ 进程内 `console.log/warn/error` **不会**出现在 stderr（只有引擎级警告会），
  写 QML 探针时用 `qml/dev/LayoutAudit.qml` 里那套 `emitOne()` 通道。

## 6. 界面设计

界面遵循 **Material Design 3**，契约在 `docs/design/MD3-SPEC.md`（唯一实现依据）：

- 颜色只用 MD3 语义角色（`Theme.colors.primary`、`surfaceContainerHigh`、`onSurfaceVariant`…），
  浅/深两套完整色板由 `src/app/thememanager.cpp` 提供，QML 里不写死色值。
- 排版只用 15 级字阶（`MdText { role: "bodyMedium" }`），不写 `font.pixelSize`。
- 圆角用 `Md3.shape.*`、间距用 `Md3.space.*`、动效用 `Md3.motion.*`；
  交互态用状态层（hover 8% / pressed 10% / disabled 38%），不改文字颜色。
- 组件一律用 `qml/components/Md*.qml`（44 个，API 冻结）；页面只做拼装。
- 软件渲染（`QT_QUICK_BACKEND=software`）下不用 shader 效果，阴影用半透明矩形近似。
- 全宽组件根上必须写 `Layout.fillWidth: true`，否则在 `ColumnLayout` 里宽度会塌成 0（见 §7.7）。

图标是 `MdIcon` 的 Canvas 自绘 24×24 线性图标集，不引入图标字体或第三方美术资产。

## 7. 发布前检查

```bash
./scripts/build.sh
./build/hyps-hub --smoke-test
./scripts/install-local.sh
# PKGBUILD 构建见 docs/install.md
```

同时确认：

- 没有改动 `~/Hyps`；
- `git status` 干净；
- 版本号在 `CMakeLists.txt`、`packaging/PKGBUILD` 中同步更新（Release 工作流会校验
  tag 名与 `pkgver` 一致，不一致直接失败）；
- **`CHANGELOG.md` 里有该版本的段落**（标题格式 `## [0.4.0] — YYYY-MM-DD`）。Release 正文
  直接取自这一段，缺段落时发布流程会失败，不会发出正文空白的 release；
- 文档中的截图与功能一致；
- 已知限制没有变化（否则更新 README/架构文档）。

发版前可以先本地预览 release 正文：

```bash
./scripts/release-notes.sh 0.4.0
```

发版就是打 tag 并推送，剩下的由 `.github/workflows/release.yml` 完成：

```bash
git tag -a v0.4.0 -m "Hyps Hub v0.4.0"
git push origin v0.4.0
```
