# 故障排查

先看「诊断」页：它展示的是真实检测结果（GUI 前置条件、上游 `init.sh --check` 报表、Hyps 组件提交与工作区状态），
并可以导出脱敏诊断包。

## 初始化相关

### 提示「未找到 git」

```bash
sudo pacman -S git
```

安装后在向导页点「重新检查」。

### 网络检查失败

- 确认能访问 GitHub：`git ls-remote https://github.com/MoYingJi/Hyps.git HEAD`
- 代理/镜像请配置在 git 层（`git config --global http.proxy ...`），Hyps Hub 会继承系统环境。
- 向导页可点「重试初始化」；Hyps Hub 不会保留失败克隆的临时目录。

### 提示「目标目录已存在且不是有效的 Hyps 仓库」

说明 `$XDG_DATA_HOME/hyps-hub/runtime/Hyps` 已存在但不满足仓库结构。Hyps Hub 出于安全考虑**不会覆盖**。
请自行检查该目录：

```bash
ls -la ~/.local/share/hyps-hub/runtime/Hyps
```

确认无需保留后再手动移走，然后重试初始化。不要直接删除来源不明的目录。

### 克隆中断

直接重试即可。Hyps Hub 只会清理本次创建的 `runtime/.Hyps.clone-*` 临时目录。

## Hyps 组件与更新

### 更新按钮不可用 / 提示有未提交修改

Hyps 组件必须保持 Git 工作区干净才能更新。打开组件目录检查：

```bash
git -C ~/.local/share/hyps-hub/runtime/Hyps status
```

Hyps Hub 不会执行 `reset` / `clean`，请自行处理这些修改后再更新。

### 更新失败

更新使用 `git merge --ff-only`，失败不会回退或清理。可在「诊断」页查看 `updateStatusText`，
或在 `~/.local/share/hyps-hub/logs/runtime.log` 与 `~/.local/state/hyps-hub/update-history.jsonl` 查看记录。

### 「Hyps 组件不完整」

检查这些文件是否存在：`config.conf`、`init.sh`、`scripts/_Hyps`、`lib/libs.sh`、`lib/common.sh`。
缺失通常意味着不是完整克隆，可导出诊断包后手动重新初始化（先移走旧目录）。

## CLI / 环境检测

### 「CLI 不可用」

- 确认 Hyps 组件就绪（顶栏 COMPONENT 标签为绿色）。
- 在「诊断」页执行「CLI 帮助」，查看原始输出。
- 确认 `bash` 已安装：上游脚本需要 Bash >= 4.3。

### 必需项缺失

「诊断」页会列出缺失项与提示。常见：

| 缺失项 | 处理 |
| --- | --- |
| `umu-run` | `sudo pacman -S umu-launcher` |
| Proton（umu-proton-ge / dwproton 等） | 安装对应 Proton，或在配置页修改 `runner.name` / `runner.protonpath` |
| `fuse-overlayfs` | `sudo pacman -S fuse-overlayfs`（启用 Overlay 时） |
| `gamescope` / `gamemoderun` / `mangohud` | 安装对应包，或关闭相应开关 |
| `mingw-w64` / `gcc` / `python3` | 只有相关可选功能需要 |

## 游戏启动

### 启动按钮不可用

游戏详情底部会显示原因：`game.exe` 缺失/占位/不存在、`runner.name` 未设置或不存在、缺少启动脚本、
或配置有未保存修改。按提示修复并保存。

### 启动失败

1. 在「任务」页查看退出码与 stderr，日志同时保存在 `~/.local/share/hyps-hub/logs/tasks/`。
2. 在「诊断」页执行「环境检测」「Proton 列表」「游戏列表」，确认上游真实状态。
3. 检查游戏配置中的 `game.exe` 是否为绝对路径且文件存在。
4. 检查运行器配置是否指向有效的 Proton（`runner.protonpath` 或 `runner.exe`）。

### 取消任务后游戏仍在运行

Hyps Hub 为任务建立独立进程组，取消时向整个进程组发送 `SIGTERM`，1.5 秒后 `SIGKILL`。
如果仍残留，通常是外部启动的进程不在该组内；请检查 `pgrep -af`，必要时手动结束。退出应用前会提示仍有任务运行。

## 界面

### 界面文字/图标异常

- 需要 `qt6-declarative`、`qt6-svg`；缺少 SVG 插件会导致图标不显示。
- 主题默认跟随系统 `color-scheme`，可在设置中固定浅色/深色。

### 终端输出出现 dconf 警告

部分桌面环境下 Qt/GTK 会输出 `dconf will not work properly`，不影响应用功能。

### 日志太多 / 想重新开始

- 「任务」页可清空历史（磁盘日志保留）。
- GUI 配置损坏时会自动备份为 `config.json.corrupt.<时间戳>` 并使用默认值；也可手动删除
  `~/.config/hyps-hub/config.json` 后重启。
- 删除 Hyps 组件、配置与日志前请确认不再需要，Hyps Hub 不会自动清理它们。

## 诊断包

「诊断」→「导出诊断包」会生成目录，包含：

- `summary.txt`、`env-report.txt`、`runtime-info.json`、`gui-config.json`
- `task-history.jsonl`、`logs/`（任务与 runtime 日志尾部）
- `README.txt`（隐私说明）

疑似 token/password/secret 的字段会被替换为 `***`。分享前仍建议自行检查内容。
