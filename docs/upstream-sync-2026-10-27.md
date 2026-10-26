# 上游同步记录 · 2026-10-27（Hyps Hub 0.3.0）

> 同步对象：上游 [MoYingJi/Hyps](https://github.com/MoYingJi/Hyps)（GPL-3.0-only，Hyps Hub 不包含其源码）。
> 基线提交 → 目标提交：`1b94dc8` → `a2ac842`。
> 对应 Hyps Hub 版本：**0.3.0**。记录日期：2026-10-27。

## 1. 区间概览

`git rev-list --count 1b94dc8..a2ac842` = **16 个新提交**（把基线 `1b94dc8` 本身计入为 17 个）。
其中 4 个提交改变了 GUI 契约，需要 Hub 侧适配；其余为内部重构、工具优化与文档修正。

| 提交 | 日期 | 类型 | 摘要 | 影响 Hub |
| --- | --- | --- | --- | --- |
| `a2ac842` | 2026-10-22 | refactor! | 移除 `hosts_disconnect` 功能 | **是**（删除字段与校验） |
| `2a622e9` | 2026-10-22 | fix | 修正 README 中的环境变量路径描述 | 否（文档） |
| `a943d2c` | 2026-10-21 | refactor | 简化并增强 yuanshen 的 `sudo_request` 调用 | 否（内部） |
| `de1f5d2` | 2026-10-21 | refactor | `sudo_request` / `run_and_log` 移入 `command.sh` | 否（内部） |
| `5cf26e0` | 2026-10-20 | fix | 修复 `IFS` 作用域 | 否（内部） |
| `79e61ed` | 2026-10-20 | fix | 增强安全性 | 否（内部） |
| `5582cf0` | 2026-10-19 | refactor | 优化部分 C 工具，修复数值溢出 | 否（内部） |
| `f527737` | 2026-10-18 | docs | 更新 endfield surrogate 示例配置 | 否（示例） |
| `a566e34` | 2026-10-18 | feat | 替身模式支持单独设置硬链接与复制目标 | **是**（新增字段） |
| `9b9a957` | 2026-10-18 | feat(endfield)! | 可提前结束启动器进程，重构替身配置项 | **是**（字段重构） |
| `4ebd42d` | 2026-10-18 | feat | gryph-surrogate 增加更多日志 | 否（内部） |
| `2c91ab4` | 2026-10-18 | feat | fpsunlock 未填 `prog` 时取 `game.exe` basename | **是**（弃用键告警） |
| `69e659f` | 2026-10-18 | fix | 修复环境变量前缀 | 否（内部） |
| `6fa55a3` | 2026-10-18 | feat | 新增直接调用游戏本体的用法 | 否（内部） |
| `fbe0e91` | 2026-10-17 | refactor | 优化参数处理逻辑 | 否（内部） |
| `2a9c148` | 2026-10-17 | fix | 移除 `gryph_surrogate_compile` 冗余编译标志 | 否（内部） |

## 2. 影响面

| 变更 | 上游行为 | Hub 适配 |
| --- | --- | --- |
| 移除 hosts 断网（`a2ac842`） | 删除 `lib/features/hosts_disconnect.sh`；`init.sh --check` 不再输出「hosts 可写」项；`features.hosts_disconnect.*` 配置不再被读取 | 通用配置删除 `features.hosts_disconnect.enabled` 字段；残留键改为告警；环境报表只渲染上游真实输出 |
| 终末地替身配置重构（`9b9a957`） | `endfield.launcher` 失效，改为 `endfield.surrogate.mode = "launcher"` + `endfield.surrogate.launcher`；新增 `exit_after`、`show_info`、`keep` | 游戏页新增「终末地替身」分区与 `endfield.surrogate.*` 字段，`mode` 用 enum 渲染 |
| 替身目标分离（`a566e34`） | 新增 `endfield.surrogate.{hardlink_,copy_}{dir,target}`，同一前缀 `dir` 与 `target` 互斥；`launcher` 模式不能与替身目标键混用 | 字段目录补齐 4 个目标键，语义校验覆盖互斥与模式冲突 |
| fpsunlock 进程名推导（`2c91ab4`） | 未设置 `gi.fps_unlock.prog` 时取 `game.exe` 的 basename 作为目标进程名；`yuanshen.example.conf` 删除该键 | `gi.fps_unlock.prog` 变为弃用告警（不阻断保存），示例配置不再包含该键 |
| 内部重构（`de1f5d2`、`5cf26e0`、`79e61ed`、`5582cf0`、`a943d2c` 等） | 函数归并、`IFS` 作用域、C 工具与安全加固 | 无契约变化，随组件升级自动生效 |

## 3. GUI 侧对应改动

### 3.1 通用配置：删除 hosts 断网

- `ConfigManager::setupFields()` 的通用字段目录不再包含 `features.hosts_disconnect.enabled`。
- `validateCommon()` 不再检查 `features.hosts_disconnect.content`，改为扫描残留键：只要存在以
  `features.hosts_disconnect.` 开头的键，就追加一条 `warning`（key 为 `features.hosts_disconnect`），
  说明上游已移除该功能、配置会被忽略、可在原始编辑器中删除。
- 配置内容不做迁移、不做自动删除：`ConfigFile` 仍原样保留未知键，用户自行决定是否清理。

### 3.2 游戏页：终末地替身分区

字段按游戏动态生成：`ConfigManager::gameFieldsFor(slug)` 返回基础字段副本，`slug == "endfield"` 时
再追加 `group = "终末地替身"` 的专属字段。QML 侧在切换游戏时重新求值字段列表，并在「基础」「高级」
之后渲染该分区（不受高级模式开关限制）。

| 键 | 类型 | 说明 |
| --- | --- | --- |
| `endfield.surrogate.mode` | enum | 未启用（空值）/ `hardlink-or-copy` / `hardlink` / `copy` / `launcher`（挂起官方启动器） |
| `endfield.surrogate.launcher` | dir | 启动器目录或 `Games.exe` 完整路径；替身模式下也作为替身源文件 |
| `endfield.surrogate.dir` | dir | 替身目录，文件名固定 `Games.exe`；与同前缀 `target` 二选一 |
| `endfield.surrogate.target` | file | 替身完整路径（自定义文件名）；与同前缀 `dir` 二选一 |
| `endfield.surrogate.hardlink_dir` / `.hardlink_target` | dir / file | 只作用于硬链接方式，优先于无前缀项 |
| `endfield.surrogate.copy_dir` / `.copy_target` | dir / file | 只作用于复制方式，优先于无前缀项 |
| `endfield.surrogate.keep` | bool | 游戏退出后保留替身文件与新建目录（默认删除） |
| `endfield.surrogate.exit_after` | int | 游戏启动后等待 N 秒结束挂起的父进程 |
| `endfield.surrogate.show_info` | bool | 用信息框显示工具的 info 日志 |

`ConfigField.qml` 新增 `enum` 类型渲染：从字段的 `options`（`{value, label}` 列表）渲染可点选项，
点击写回配置值；`value` 为空的选项表示「未启用」，点击后删除该键，回到上游默认行为。
其余 `bool / text / int / file / dir / runner / array` 行为不变。

### 3.3 语义校验（仅 `endfield` 生效，除最后一条）

| 规则 | 触发条件 | 级别 |
| --- | --- | --- |
| 缺少 mode | `mode` 为空但存在其他 `endfield.surrogate.*` 键（只有空 `mode` 视为不启用） | error |
| mode 非法 | `mode` 不在 `launcher` / `hardlink` / `copy` / `hardlink-or-copy` | error |
| launcher 模式冲突 | `mode = launcher` 时缺少 `launcher`，或同时存在 `dir`/`target`/`hardlink_*`/`copy_*` | error |
| 目标二选一 | 前缀 `""`、`hardlink_`、`copy_` 中任一同前缀 `dir` 与 `target` 同时存在（替身模式下校验） | error |
| exit_after 非法 | `exit_after` 存在但不是正整数（替身模式下校验） | error |
| fpsunlock 弃用键 | 任意游戏配置中存在 `gi.fps_unlock.prog` | warning |

`error` 阻止保存，`warning` 只提示并要求确认——与既有校验策略一致。

### 3.4 原神：`gi.fps_unlock.prog` 弃用

上游改为未设置时取 `game.exe` basename，因此该键不再需要。Hub 不删除用户配置，只在
`validateGame()` 里给出弃用告警；`yuanshen` 示例配置中也不再包含该键。原始编辑器仍可编辑它
（未识别键原样保留），便于用户自行清理。

## 4. 升级本地组件

组件位于 `$XDG_DATA_HOME/hyps-hub/runtime/Hyps`（默认 `~/.local/share/hyps-hub/runtime/Hyps`），
只做快进合并，不执行 `reset --hard` / `clean` / `checkout` 覆盖用户修改：

```bash
cd "${XDG_DATA_HOME:-$HOME/.local/share}/hyps-hub/runtime/Hyps"
git status --porcelain          # 必须为空，否则先处理本地修改
git fetch --prune origin
git merge --ff-only a2ac842
git log -1 --oneline            # 期望：a2ac842 refactor!: 移除 hosts_disconnect 功能
```

也可以走 GUI：**诊断 → 检查更新 → 应用更新**（内部即 `git fetch` + `git merge --ff-only`，
脏工作区直接拒绝并说明原因），更新前后提交写入 `update-history.jsonl` 与 `runtime.log`。

升级完成后在诊断页重跑环境检测：报表中不再出现「hosts 可写」，替身相关能力按上游新逻辑生效。

## 5. 兼容性与回滚

- **配置兼容**：0.2.0 时代的配置在 0.3.0 中照常读取；旧键保留、不写新键、不自动删除，只是多出
  残留/弃用告警。
- **回滚**：需要回到旧行为时，在干净工作区把组件切回 `1b94dc8`；Hyps Hub 不会自动回退，也不在
  更新流程里使用破坏性 Git 操作。GUI 侧回滚需同时回退到 0.2.0 安装包。
- **不做的兼容**：不为已移除的 `hosts_disconnect` 保留隐藏开关或“兼容模式”。

## 6. 未跟进项

- `2a622e9`（README 环境变量路径）、`f527737`（示例配置注释）：纯文档，Hub 文档独立维护。
- `de1f5d2` / `a943d2c` / `5cf26e0` / `79e61ed` / `5582cf0` / `2a9c148` / `4ebd42d`：内部实现与
  日志优化，不改变 GUI 契约，随组件升级自动生效。
- 若上游后续恢复 hosts 断网能力，需要重新加回字段目录与校验规则；当前不预留。

验证记录与测试清单见 [verification.md](verification.md)，安装与版本号落点见 [install.md](install.md)。
