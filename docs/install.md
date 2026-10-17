# 安装与卸载

## 1. 依赖

### 运行时依赖（Arch 包名）

```bash
sudo pacman -S --needed qt6-base qt6-declarative qt6-svg bash git
```

游戏运行所需的 `umu-launcher`、Proton、MangoHud、GameMode、gamescope、fuse-overlayfs 等属于上游 Hyps 的
依赖，Hyps Hub 不重复打包；首次初始化后可在「诊断」页看到真实缺失项。

### 构建依赖

```bash
sudo pacman -S --needed base-devel cmake ninja qt6-base qt6-declarative qt6-svg
```

## 2. 从源码构建

```bash
git clone <本仓库地址> Hyps-Hub
cd Hyps-Hub
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

产物：`build/hyps-hub`。直接运行即可，首次启动会进入初始化向导。

## 3. 本地安装（无需 root）

```bash
./scripts/install-local.sh
```

默认安装到 `~/.local`：

- `~/.local/bin/hyps-hub`
- `~/.local/share/applications/hyps-hub.desktop`
- `~/.local/share/icons/hicolor/scalable/apps/hyps-hub.svg`
- `~/.local/share/doc/hyps-hub/`、`~/.local/share/licenses/hyps-hub/`

如果 `~/.local/bin` 不在 `PATH` 中，请自行加入。

## 4. 从 GitHub Releases 安装

发布页会提供：

- `hyps-hub-<版本>-1-x86_64.pkg.tar.zst`（Arch 安装包）
- `hyps-hub-<版本>.tar.gz`（源码包）
- `SHA256SUMS`

```bash
sudo pacman -U hyps-hub-0.1.0-1-x86_64.pkg.tar.zst
```

CI（Arch Linux 容器）会在每次推送到 `main` 时构建并运行 CTest；推送 `v*` 标签时自动构建安装包并创建 GitHub Release。

## 5. Arch Linux 手工打包

`packaging/PKGBUILD` 使用本地源码包 `hyps-hub-<版本>.tar.gz`。发版时也可以改成上游 tarball/源码地址。

```bash
# 1) 生成源码包（在仓库根目录）
git archive --prefix=hyps-hub-0.1.0/ -o hyps-hub-0.1.0.tar.gz HEAD

# 2) 准备打包目录
mkdir -p /tmp/hyps-hub-pkg
cp packaging/PKGBUILD hyps-hub-0.1.0.tar.gz /tmp/hyps-hub-pkg/
cd /tmp/hyps-hub-pkg

# 3) 构建并打包（不安装）
makepkg -f

# 4) 安装
sudo pacman -U hyps-hub-0.1.0-1-x86_64.pkg.tar.zst
```

注意：

- 包名 `hyps-hub`，可执行文件 `hyps-hub`。
- 用户配置、Hyps 组件、日志不会被安装到系统目录；运行时才在 XDG 目录中创建。
- 卸载包不会删除用户数据。

## 6. 卸载

### 包管理器

```bash
sudo pacman -Rns hyps-hub
```

### 本地安装

```bash
./scripts/uninstall-local.sh
```

两种方式都**不会**删除：

- `~/.local/share/hyps-hub/`（Hyps 组件、缓存、日志、prefix）
- `~/.config/hyps-hub/`（GUI 配置与 Hyps CLI 配置）
- `~/.local/state/hyps-hub/`（任务历史、更新记录、环境检测结果）

如需彻底清理，请确认不再需要这些数据后手动删除上述目录。

## 7. 首次启动

1. 向导会检查 Git、Bash、数据目录与网络。
2. 点击「开始初始化」后，会把上游 `https://github.com/MoYingJi/Hyps.git` 克隆到
   `$XDG_DATA_HOME/hyps-hub/runtime/Hyps`（默认 `~/.local/share/hyps-hub/runtime/Hyps`）。
3. 克隆完成后自动执行 `init.sh --no-game`，把配置写入隔离的 `CONFIG_DIR`。
4. 进入主界面后可在「诊断」页运行环境检测。

整个过程不会读取、修改、移动或清理 `~/Hyps`。

## 8. 构建可复现性

- 版本号来自 CMake 的 `project(HypsHub VERSION ...)`。
- 构建信息（Git commit）由 CMake 在配置时读取仓库 HEAD；无 Git 仓库时显示 `unknown`。
- 测试通过 `ctest` 执行；网络相关的真实克隆测试默认禁用（`tst_network_e2e`）。
