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
    thememanager.*             Ark 色板、深浅色、跟随系统
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
qml/                           Ark 设计语言界面（见 docs/design/）
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

- `--smoke-test`：加载 QML 后 1.5s 退出，用于检查 QML 错误。
- `--screenshot <path>`：加载后保存窗口截图（需要 `QT_QPA_PLATFORM=offscreen` 或真实会话）。
- `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software`：无显示环境下的 QML 验证。
- 日志：`~/.local/share/hyps-hub/logs/`；任务日志在 `logs/tasks/`。
- Hyps 组件日志：`logs/runtime.log`；更新记录：`~/.local/state/hyps-hub/update-history.jsonl`。

## 6. 界面设计

界面遵循用户提供的 Ark 设计规范（见 `docs/design/`）：

- 近黑墨底 `#080a0b`、纸阶文字、单一青色信号 `#18d1ff`；酸性绿只表状态。
- 0 圆角、1px 细线、左上/右下 45° 切角、单条左侧强边、取景框角标。
- NN 索引、等宽微标签、大写字母、`tabular` 数字。
- 噪点 + 蓝图网格 + 45° 警戒线双纹理。
- 交互目标 >= 40px（按钮默认 44px）；禁止无限旋转 loading / 回弹缓动。

**不要从官网或游戏资源中引入鹰角专有美术资产。** 项目是 GPL 开源分发，图形均为原创几何标记、
自生成纹理与自绘线性图标。需要官方视觉氛围时，应通过用户自选本地壁纸等不分发资产的方式实现。

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
- 版本号在 `CMakeLists.txt` 中更新；
- 文档中的截图与功能一致；
- 已知限制没有变化（否则更新 README/架构文档）。
