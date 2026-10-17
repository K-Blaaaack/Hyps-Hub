# Hyps Hub

[![CI](https://github.com/K-Blaaaack/Hyps-Hub/actions/workflows/ci.yml/badge.svg)](https://github.com/K-Blaaaack/Hyps-Hub/actions/workflows/ci.yml)
[![Release](https://github.com/K-Blaaaack/Hyps-Hub/actions/workflows/release.yml/badge.svg)](https://github.com/K-Blaaaack/Hyps-Hub/actions/workflows/release.yml)

Hyps Hub 是 [Hyps](https://github.com/MoYingJi/Hyps) CLI 的原生 Linux 桌面客户端（Qt 6 / QML），
目标是让你用图形界面完成 Hyps 的日常操作，同时保持 **GUI 与 CLI 解耦、运行环境独立、数据隔离**。

![首页](docs/screenshots/home.png)

## 特性

- **首次初始化向导**：检查 Git / Bash / 网络，异步克隆独立的 Hyps 组件（带进度、失败可重试）。
- **完全隔离**：Hyps 组件位于 `$XDG_DATA_HOME/hyps-hub/runtime/Hyps`；调用 CLI 时注入
  `CONFIG_DIR / CACHE_DIR / DATA_DIR / TEMP_DIR`，不写入 `~/Hyps`，也不与 `~/.config/hypsc` 等目录混用。
- **环境检测**：调用上游 `init.sh --check` 并解析真实报表（必需项/可选能力/配置状态）。
- **游戏配置与启动**：读取 `CONFIG_DIR/games/*.conf`，可视化编辑 `game.exe`、`runner.name`、`game.args` 等；
  启动时调用上游 `scripts/<Game>.sh`，实时显示 stdout/stderr、退出码，可按进程组取消任务。
- **配置管理**：通用配置（MangoHud、GameMode、缓存、taskset、Overlay、时长记录等）与运行器配置可视化编辑；
  保存前校验、自动 `.bak.<时间戳>` 备份、原始文本编辑器（保留注释与顺序）。
- **任务与日志**：任务历史（最多 200 条）、逐任务日志落盘、过滤/复制/清空视图、退出时清理子进程。
- **诊断**：环境报表、Hyps 组件状态、手动检查更新（`git fetch` + `git merge --ff-only`，脏工作区拒绝更新）、
  白名单诊断命令、脱敏诊断包导出。
- **Ark 设计语言界面**：近黑墨底、单一青色信号、0 圆角、1px 细线、45° 切角、NN 索引与双纹理；
  跟随系统深浅色，支持手动切换。

## 截图

| 首次初始化 | 游戏配置与启动 | 关于 |
| --- | --- | --- |
| ![初始化](docs/screenshots/onboarding.png) | ![游戏](docs/screenshots/games.png) | ![关于](docs/screenshots/about.png) |

### 添加游戏配置

`TEMPLATE` 表示隔离的 `CONFIG_DIR/games/` 里还没有该游戏的配置；点击「创建」会从上游
`config/games.examples` 复制一份，不覆盖已有配置，也不读取或修改 `~/Hyps`。

<img src="docs/screenshots/add-game.png" alt="添加游戏配置" width="720">

## 依赖

运行时：

- Arch：`qt6-base qt6-declarative qt6-svg bash git`
- 运行游戏还需要上游 Hyps 所需的依赖（`umu-launcher`、Proton、MangoHud、GameMode、gamescope 等）。
  Hyps Hub 不重复实现这些依赖，只在诊断中展示缺失项。

构建：

```bash
sudo pacman -S --needed base-devel cmake ninja qt6-base qt6-declarative qt6-svg
```

## 构建与运行

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
./build/hyps-hub
```

或使用脚本：

```bash
./scripts/build.sh          # 构建 + 测试
./scripts/run.sh            # 构建后启动
```

## 安装

### 本地安装（无需 root）

```bash
./scripts/install-local.sh  # 安装到 ~/.local
```

### Arch Linux 包

```bash
# 在仓库根目录生成源码包（PKGBUILD 使用本地源码包）
git archive --prefix=hyps-hub-0.1.0/ -o hyps-hub-0.1.0.tar.gz HEAD
mkdir -p /tmp/hyps-hub-pkg && cp packaging/PKGBUILD hyps-hub-0.1.0.tar.gz /tmp/hyps-hub-pkg/
cd /tmp/hyps-hub-pkg && makepkg -f
```

详见 [docs/install.md](docs/install.md)。

## 数据与隔离

| 路径 | 内容 |
| --- | --- |
| `~/.local/share/hyps-hub/runtime/Hyps` | 独立 Hyps Git Hyps 组件 |
| `~/.local/share/hyps-hub/logs` / `cache` / `hyps-data` | 日志、缓存、prefix/overlay/时长记录 |
| `~/.config/hyps-hub/config.json` | Hyps Hub 自身配置 |
| `~/.config/hyps-hub/hyps` | 注入给 Hyps CLI 的 `CONFIG_DIR` |
| `~/.local/state/hyps-hub` | 任务历史、环境检测结果、更新历史 |

实际路径按 `XDG_DATA_HOME` / `XDG_CONFIG_HOME` / `XDG_STATE_HOME` 解析。

**卸载应用不会删除 Hyps 组件、配置与日志**；需要彻底清理时手动删除上述目录。

## 安全边界

- 所有 CLI 调用都经过 `HypsAdapter`，使用程序 + 参数数组，不经过 shell，不提供任意命令执行器。
- 更新仅在 Git 工作区干净时执行 `fetch` + `merge --ff-only`；从不执行 `reset --hard` / `clean`。
- 克隆失败只清理本次创建的 `runtime/.Hyps.clone-*` 临时目录。
- 诊断导出会对 `token/password/secret/api_key/auth` 字段脱敏。
- 默认不使用 root；上游 CLI 本身也会拒绝 root。

## 开发

架构、适配层契约、测试与设计规范见：

- [docs/research.md](docs/research.md) — 上游调研、能力映射、技术选型
- [docs/architecture.md](docs/architecture.md) — 分层、目录、状态机、适配层
- [docs/development.md](docs/development.md) — 构建、测试、调试
- [docs/verification.md](docs/verification.md) — 构建、测试、打包与验收记录
- [docs/troubleshooting.md](docs/troubleshooting.md) — 故障排查
- [docs/design/](docs/design/) — Ark 设计语言参考（仅设计语言，不含鹰角专有资产）

## 已知限制

- 上游没有游戏库扫描、自动下载/安装游戏或 Proton 的能力，Hyps Hub 也不会伪造这些功能。
- 游戏启动的真实性依赖用户已安装的游戏与 Proton/umu 环境；自动化测试使用假 Hyps 组件验证适配层，不启动真实游戏。
- 更新使用 Git 快进合并；如果本地 Hyps 组件存在未提交修改，GUI 会拒绝更新，需要用户手动处理。
- 未提供 Flatpak/AppImage：沙箱对宿主机 GPU/游戏环境有实际限制，不做未验证的交付。
- 未实现 P1/P2 的配置导入导出、桌面通知的细粒度设置、多运行环境模板等，详见架构文档。

## 许可

GPL-3.0-only。上游 Hyps 亦为 GPL-3.0-only，但本项目不包含其源码；运行时由用户机器上的独立组件提供。
