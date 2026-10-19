# MAGI 全面审查：Hyps Hub

> 审查对象：`/home/kb/github/Hyps-Hub`，HEAD `6b12734`，版本 `0.1.7`  
> 审查日期：2026-10-19  
> 审查方式：MELCHIOR（正确性/可靠性）、BALTHASAR（安全/隐私/隔离）、CASPER（产品/可维护性/交付）三席分线取证，交叉复核。  
> 证据基线：源码与文档静态审查、现有 CTest 9/9、CI 与 Release `v0.1.7` 结果。未修改任何产品代码。

---

## 0. MAGI 裁决

| 席位 | 结论 | 核心理由 |
| --- | --- | --- |
| MELCHIOR | **有条件通过** | 进程执行、克隆/更新状态机、配置备份设计扎实；但启动日志加载、无单实例、未保存配置关闭存在可靠性/数据完整性风险。 |
| BALTHASAR | **反对直接公开发布** | 诊断包脱敏会漏掉 `Authorization: Bearer`、CLI 参数和带凭据 URL；Git 环境/钩子未隔离；发布链未固定。 |
| CASPER | **有条件通过** | 功能闭环、视觉一致、文档完整；但可访问性、UI 自动化测试、截图版本漂移需要补齐。 |
| **合议** | **有条件通过（2:1）** | **本地单用户 MVP 可用；在修复 4 项 P0 前，不建议作为 1.0 广泛发布。** |

**P0 阻断项：** F-01 诊断脱敏、F-02 启动日志加载、F-03 单实例/并发写、F-04 未保存配置关闭。

---

## 1. 审查范围与证据

- 源码：`src/`（约 5,995 行 C++）、`qml/`（页面、组件、对话框）、`tests/`（10 个 CTest，9 个启用）。
- 交付：`CMakeLists.txt`、`packaging/PKGBUILD`、`.github/workflows/ci.yml`、`.github/workflows/release.yml`。
- 文档：README、安装/验证/架构/故障排查、`docs/credits.md`、设计文档。
- 运行证据：
  - `ctest --test-dir build --output-on-failure` → **9/9 passed**；`tst_network_e2e` Disabled。
  - GitHub Actions：CI 与 Release `v0.1.7` 均 success；Release 资产为 Arch 包、源码包、`SHA256SUMS`。
- 未执行：真实游戏启动、真实 Wayland 交互、D-Bus 通知守护进程、安装后完整包测试、`clang-tidy`/ASan（未生成 `compile_commands.json`）。
- 说明：MAGI 工具层拒绝了团队枚举和一次混合构建命令，未绕过保护；本报告按三席视角分线审查同一代码库，不使用未经验证的结论。

---

## 2. 风险总表

| ID | 级别 | 类别 | 结论 |
| --- | --- | --- | --- |
| F-01 | **P0 / High** | 隐私 | 诊断包脱敏覆盖不足，可能泄露 Token、Bearer、URL 凭据 |
| F-02 | **P0 / High** | 可靠性 | 启动时同步加载完整任务日志，大日志可卡死启动 |
| F-03 | **P0 / High** | 数据完整性 | 无单实例锁；并发写配置/历史/更新可能互相覆盖 |
| F-04 | **P0 / High** | 数据丢失 | 关闭窗口只检查运行任务，不检查未保存配置/原始文本 |
| F-05 | P1 / Medium | 诊断正确性 | `tailOfFile` 读文件前 8MB 而非尾部；导出同步执行最多约 80MB |
| F-06 | P1 / Medium | 发布溯源 | 发布包由无 `.git` 的源码 tar 构建，二进制内提交号变成 `unknown` |
| F-07 | P1 / Medium | 供应链 | Git 子进程继承 `GIT_*`/全局配置，未禁用钩子与校验远端 |
| F-08 | P1 / Medium | 诊断可靠性 | 写诊断文件不检查 `write()` 返回值，失败仍报成功 |
| F-09 | P1 / Medium | 数据生命周期 | 任务日志、运行日志、更新历史无上限；清空历史不删日志 |
| F-10 | P1 / Medium | 正确性 | 游戏目录接受任意 `*.conf`，但游戏配置 API 只接受 `[a-z0-9_]`，带连字符配置无法编辑/启动 |
| F-11 | P1 / Medium | 隐私/UX | 隐藏的诊断页在每次启动时自动访问 GitHub |
| F-12 | P1 / Medium | 可访问性 | 导航轨/任务行仅 MouseArea，无键盘可达；大量 8–10px 微标签 |
| F-13 | P1 / Medium | 测试 | 无 TaskManager/QML 交互测试；最近滚动/编辑器问题未被自动化捕获 |
| F-14 | P1 / Medium | 供应链 | Actions 用浮动 tag、Arch 镜像 `latest`、`sha256sums=('SKIP')`、发布无签名 |
| F-15 | P2 / Low | 文档 | 截图版本落后（About v0.1.5 vs 0.1.7）、`credits.png` 孤立、术语“运行副本”残留 |
| F-16 | P2 / Low | 打包 | PKGBUILD `url` 指向上游而非本项目；无 AppStream metainfo |
| F-17 | P2 / Low | UX | 窗口几何恢复只校验 ≥640×480，不按屏幕边界收敛，可能开出屏外 |
| F-18 | P2 / Low | 日志正确性 | System 与 stdout 共用 partial 缓冲；长行写入/扫描为 O(n²) |
| F-19 | P2 / Low | 安全加固 | 以 root 运行只提示不阻止；GUI 仍会写 root 的 XDG 目录 |
| F-20 | P2 / Low | 文案 | 关于页仍写“用户提供的 Ark 设计规范”，属于自我指涉的残留表述 |

---

## 3. P0：发布前必须修复

### F-01 诊断包脱敏不可靠，可能泄露密钥

**证据**

- `src/diagnostics/diagnostics.cpp:41-49` 仅用一条正则：
  `(token|password|passwd|secret|api[_-]?key|authorization|auth)([\s"']*[:=][\s"']*)([^\s"',]+)`
- 现有测试 `tests/tst_diagnostics.cpp` 只覆盖 `TOKEN=supersecret-value`、`"password":"hunter2"`、`api_key=...` 三种简单形式。
- 以下真实形式无法正确处理：
  - `Authorization: Bearer abc123` → 只替换 `Bearer`，`abc123` 留在导出包。
  - `--token abc123` / `token abc123`（空格分隔）→ 完全匹配不到。
  - `api_key: "abc def"` → 只替换到第一个空格，剩余 `def"` 泄露。
  - `https://user:password@github.com/...` → 无关键字，原样导出。
- `docs/verification.md` 与 README 均宣称“疑似 token/password/secret 字段已被替换为 ***”。

**影响**  
诊断包通常被用户上传到 Issue/聊天群；一旦任务日志或 Git 错误里出现认证头、CLI 密钥或带凭据 URL，会直接泄露。这是对产品隐私承诺的直接违背，BALTHASAR 因此投反对票。

**建议**

1. 使用多组定向规则：`Authorization: <scheme> <value>`、`--token/--password/--api-key`、`KEY=value`、URL userinfo、JSON 引号值。
2. 对整行做“敏感键后全部值”替换，而不是只替换第一个 token。
3. 增加 10+ 种格式的回归测试；对真实任务日志做脱敏快照。
4. 在修复前，把 README/诊断包说明改成“尽力脱敏，请自行检查”，不要承诺“已替换”。

---

### F-02 启动时同步加载完整任务日志，大日志可卡死启动

**证据**

- `TaskManager` 构造函数调用 `loadHistory()`（`src/app/taskmanager.cpp:212-220`）。
- `loadHistory()` 最后调用 `setCurrentTask(m_model->taskAt(0))`（`:290-292`）。
- `setCurrentTask()` 对非活动历史任务立即 `loadLogInto(task)`（`:538-550`）。
- `loadLogInto()` 用 `readLine()` 逐行读取整个文件（`:646-672`），期间持续向 `LogModel` 插入行。
- `TaskManager` 在 QML 引擎加载前构造（`src/main.cpp:79`）。

**影响**  
用户启动过一个输出很大的游戏/诊断任务后，下次启动会在窗口出现前同步读完整日志；日志没有大小上限，可能数十到数百 MB，造成启动无响应。选择历史任务时同样会卡住 UI。

**建议**

- 启动时只加载元数据，不加载日志正文；进入任务页或选中任务时再加载。
- 只读末尾 N MB/N 行，使用 `QFile::seek` 从尾部读；设置硬上限。
- 大日志异步读取、分批 append，显示进度；不要在 GUI 线程全量读。
- 增加“100MB 日志启动耗时”回归测试。

---

### F-03 无单实例锁，并发写可能破坏状态

**证据**

- `src/main.cpp` 直接构造 `TaskManager`、`RuntimeManager`、`ConfigManager` 并启动刷新/克隆；没有 `QLockFile`/`QLocalServer`/单实例检查。
- `ConfigFile::save()`（`src/adapter/configfile.cpp:555-611`）是“读内存 → 备份 → QSaveFile 覆盖”，没有文件锁或 mtime 冲突检测。
- `TaskManager::appendHistory()`/`trimHistoryFile()`（`:674-725`）对同一 JSONL 追加/重写，没有跨进程锁。
- `RuntimeManager::startClone()`/`applyUpdate()` 也假设只有一个写入者。

**影响**  
两个实例同时编辑同一配置、同时结束任务、同时更新组件时，可能出现：
- 后写覆盖前写（备份只能找回旧文件，不能合并）；
- 任务历史 JSONL 行交错或截断；
- 克隆/更新竞争目标目录，产生“目标已存在/无效”状态。

**建议**

1. 启动时在 `stateDir` 创建 `QLockFile`（PID + 主机名），拿不到锁就激活已有窗口或退出并提示。
2. 配置保存记录 mtime/hash，发现外部修改时要求用户确认覆盖/重新加载。
3. 任务历史与 runtime-info 使用单写者锁或原子重写。
4. 加“双进程并发保存”回归测试。

---

### F-04 关闭窗口不检查未保存配置，静默丢失编辑

**证据**

- `qml/Main.qml:106-111` 的 `onClosing` 只检查 `Tasks.activeCount > 0`，没有检查 `Configs.common.dirty`、`gameCfg.dirty`、`runnerCfg.dirty`。
- `GamesPage.qml:57`、`ConfigPage.qml:271` 等只在页面内根据 dirty 启用保存按钮；没有全局退出守卫。
- `RawEditorDialog` 的“关闭”/Esc 直接 `close()`，没有未保存确认。
- 关闭时只调用 `saveGeometry()`，不保存配置草稿。

**影响**  
用户改了游戏参数或原始配置，未点保存就关窗，应用直接退出；备份只覆盖“已保存前的旧文件”，草稿从未写入磁盘。原始编辑器里的大量修改尤其容易丢失。

**建议**

- 汇总 `ConfigManager` 与打开中的 RawEditorDialog 的 dirty 状态，在 `onClosing` 中弹出“保存/放弃/取消”。
- RawEditorDialog 关闭时若 `editor.text` 与打开时不同，二次确认。
- 提供“保存全部”入口；不要把保存责任只放在单页按钮。

---

## 4. P1：下个版本修复

### F-05 诊断尾读逻辑错误，且导出同步阻塞 UI

- `Diagnostics::tailOfFile()` 先 `file.read(8 * 1024 * 1024)`，再取这个前 8MB 的最后 N 行（`src/diagnostics/diagnostics.cpp:52-61`）。文件大于 8MB 时，真正的最新错误不会被导出，名称“tail”名不副实。
- `exportBundle()` 最多读取 10 个任务日志，每个 8MB，合计约 80MB；它在 QML 点击回调中同步执行（`:235-242`），会冻结 UI。
- **建议**：从文件末尾 seek 读取固定窗口；限制总导出大小；异步导出并显示进度；测试 >8MB 日志只包含尾部。

### F-06 发布包内构建提交号变成 `unknown`

- `CMakeLists.txt:24-36` 只在源码目录存在 `.git` 时执行 `git rev-parse`，否则回退 `"unknown"`。
- Release 工作流先 `git archive` 生成源码 tar（`.github/workflows/release.yml:47-48`），再 `makepkg`（`:54`）；`git archive` 不包含 `.git`，makepkg 解包目录也没有 `.git`。
- 结果：Release 二进制 About 页/诊断摘要中的 build commit 为 `unknown`，无法从已安装包追溯到提交。
- **建议**：工作流把 `GITHUB_SHA` 作为 CMake cache 变量传入，并让 CMake 优先使用该变量；增加“解包后检查 About/`--version` 提交号”的发布测试。

### F-07 Git 子进程继承完整环境，未隔离钩子/配置

- `src/runtime/runtimemanager.cpp:38-43` 只设置 `GIT_TERMINAL_PROMPT=0`，其余 `QProcessEnvironment::systemEnvironment()` 原样继承。
- 这会继承 `GIT_DIR`、`GIT_WORK_TREE`、`GIT_INDEX_FILE`、`GIT_CONFIG_GLOBAL/SYSTEM`、`GIT_SSH_COMMAND`、`GIT_ASKPASS` 等；它们可以改变 `-C` 的目标、远端、凭据来源或执行命令。
- `git merge` 默认会执行仓库的 `post-merge` 钩子；组件仓库一旦被植入钩子，更新阶段就会执行。
- **建议**：构造 Git 环境白名单；固定 `GIT_CONFIG_GLOBAL`/`GIT_CONFIG_SYSTEM`/`GIT_CONFIG_NOSYSTEM`；用 `-c core.hooksPath=/dev/null` 禁用钩子；更新前校验 `origin` URL 与预期一致。

### F-08 诊断文件写入忽略 `write()` 失败

- `Diagnostics::writeTextFile()` 打开文件后直接 `file.write(content.toUtf8())`，未检查返回值或 `file.error()`，随后返回 `true`（`src/diagnostics/diagnostics.cpp:64-77`）。
- 磁盘满、配额、I/O 错误时会生成截断文件，但 `exportBundle()` 仍报告成功。
- **建议**：检查写入字节数、`flush()` 与 `error()`；失败立即返回并清理半成品；增加只读/磁盘满模拟测试。

### F-09 日志与历史生命周期不完整

- 任务历史 JSONL 限制 200 条，但每个任务的 `.log` 永不清理；`clearFinishedHistory()` 只删历史文件，不删日志（`src/app/taskmanager.cpp:639-641`）。
- `RuntimeManager::appendRuntimeLogFile()` 每次追加、无轮转（`src/runtime/runtimemanager.cpp:144-157`）；`writeUpdateHistory()` 同样无上限（`:208-226`）。
- 长期使用会持续占盘；诊断导出又会优先读最近日志，旧日志成为“看不见的垃圾”。
- **建议**：按大小/天数保留；`clearFinishedHistory` 同步清理无引用日志；runtime log 轮转；在设置/诊断页显示占用并提供清理。

### F-10 游戏 `.conf` 发现与编辑的 slug 规则不一致

- `GameCatalog` 接受目录下所有 `*.conf`，slug 直接取 `completeBaseName()`（`src/adapter/gamecatalog.cpp:182-185`）。
- `ConfigManager::gameConfig()` 只接受 `^[a-z0-9_]+$`（`src/adapter/configmanager.cpp:291-305`）；`HypsAdapter::createGameConfig()` 同样限制（`src/adapter/hypsadapter.cpp:222-228`）。
- 用户手动放一个 `my-game.conf`（或上游未来出现带连字符的 slug）时，列表能看到，但选择后 `gameCfg` 为 null，界面报“非法的游戏名”，无法编辑/启动。
- **建议**：统一 slug 规范；若上游允许 `-`，放宽到 `[a-z0-9_-]+`；否则在扫描时过滤并提示重命名；加测试。

### F-11 隐藏的诊断页在每次启动时自动访问 GitHub

- `DiagnosticsPage.qml:16-28` 在 `Component.onCompleted` 与 Runtime stateChanged 时调用 `ensureNetworkCheck()`；页面在 `StackLayout` 中随主窗口一起实例化（`qml/Main.qml:150-161`）。
- 即使用户从未打开诊断页，每次启动也会执行 `git ls-remote https://github.com/MoYingJi/Hyps.git HEAD`。
- **影响**：不必要的网络请求/隐私足迹、离线环境延迟、启动期额外 Git 进程。
- **建议**：只在诊断页首次可见时检查；或明确设置项；缓存最近结果。

### F-12 可访问性缺口

- 导航轨 delegate 只有 `MouseArea`（`qml/components/NavRail.qml:115-125`），没有 `activeFocusOnTab`/`Keys`；虽然设置了 `Accessible.role`，但无法用键盘聚焦。
- 任务行同样只有 `MouseArea`（`qml/components/TaskItem.qml:124-129`），没有 `Accessible.name/role`，键盘用户无法选择任务。
- 大量 `MicroLabel` 使用 8–10px、`disabled`/`muted` 低对比色；无系统字体缩放适配。
- **建议**：用 `Button`/`ItemDelegate` 或显式 focus + Keys；补 `Accessible` 属性；提供字号/对比度选项；加键盘遍历测试。

### F-13 测试与静态分析门禁不足

- 9 个启用测试覆盖 AppPaths/ConfigFile/EnvironmentReport/ProcessRunner/RuntimeManager/HypsAdapter/GameCatalog/Diagnostics/Smoke。
- **没有** TaskManager 单测、ConfigManager/GameCatalog 路径一致性测试、QML 交互测试；`tst_smoke` 只验证 QML 能加载。
- 最近的滚动失效、原始编辑器不可滚动、任务列表字段为空，都是用户先发现，说明 UI 回归门禁缺失。
- CMake 未设置 `-Wall/-Wextra/-Werror`；CI 没有 `clang-tidy`/`qmllint`/ASan；`tst_network_e2e` 默认禁用。
- **建议**：QML TestCase（键盘/滚动/对话框）、TaskManager 日志与结束状态测试、脱敏边界测试；CI 加 `qmllint` 和静态分析；关键路径加 ASan job。

### F-14 发布链供应链加固不足

- Actions 使用浮动 major tag：`actions/checkout@v7`、`upload-artifact@v7`、`download-artifact@v8`、`softprops/action-gh-release@v3`（`ci.yml:31`；`release.yml:30,61,75,81`）。
- 容器使用 `archlinux:latest` 并 `pacman -Syu`，构建不可复现。
- `packaging/PKGBUILD:23` 为 `sha256sums=('SKIP')`；Release 的 `SHA256SUMS` 未签名，也没有 build provenance/SBOM。
- **建议**：Actions 固定到 commit SHA；容器固定 digest；源码/依赖使用校验和；发布加 Sigstore/cosign 或至少 GPG 签名；生成 SBOM。

---

## 5. P2：待办与文档卫生

### F-15 截图与文档漂移

- `docs/screenshots/about.png` 页脚仍是 **v0.1.5**，当前版本 0.1.7；README 教程直接引用该图。
- `docs/screenshots/credits.png` 为 **v0.1.6** 的 About 顶部图，但 README 没有任何引用（孤立文件）。
- `docs/verification.md:47` 仍使用“运行副本”术语，与“Hyps 组件”不统一。
- `docs/verification.md:80-86` 安装内容清单未包含已安装的 `credits.md`。
- 截图中包含 `/home/kb/...` 本地路径与用户名；公开仓库存在轻度隐私暴露。
- **建议**：在当前版本重生成全部截图；删除未引用的 `credits.png`；统一术语；更新安装清单；截图前用 `/home/user` 等占位路径。

### F-16 PKGBUILD 元数据

- `url` 指向上游 `https://github.com/MoYingJi/Hyps`，不是 Hyps Hub 项目页。
- 无 AppStream metainfo、无 `provides`/`conflicts`（当前非必须）。
- **建议**：改为项目主页；补 `metainfo.xml`；保持 `license`/依赖同步。

### F-17 窗口几何恢复未按屏幕收敛

- `qml/Main.qml:71-80` 只判断 `width >= 640 && height >= 480`，直接采用 JSON 中的 x/y/width/height。
- 显示器拔插、分辨率变化或损坏配置可能导致窗口开出屏幕外/过大。
- **建议**：用 `Screen.availableGeometry` 收敛尺寸，校验 x/y 是否落在任一屏幕；Wayland 保持忽略位置。

### F-18 日志缓冲与长行性能

- `TaskManager::writeStream()` 将 System 与 stdout 共用 `partial[0]`（`src/app/taskmanager.cpp:421-450`）；stdout 无换行时写入 System 行会把两者拼在一起。
- `LogModel::appendChunk()` 对未换行长行反复从 0 扫描，最坏 O(n²)（`src/app/logmodel.cpp:100-130`）。
- **建议**：System 独立缓冲；限制单行长度并标记截断；分块扫描；对超大输出做采样/警告。

### F-19 root 仅提示，不阻止

- `TopBar`/`HomePage` 显示 root 警告；`AppPaths::runningAsRoot()` 仅用于展示，应用仍可写入 root 的 XDG 目录并发起 D-Bus。
- 上游 Hyps 会拒绝 root 游戏启动，GUI 不应让用户误以为可正常使用。
- **建议**：默认拒绝 root 启动，提供显式 `--allow-root`；文档说明。

### F-20 “用户提供的设计规范”残留

- `qml/pages/AboutPage.qml:373` 仍写“界面遵循用户提供的 Ark 设计规范”。
- 用户在鸣谢中已明确不希望“感谢自己提供设计规范”；这句话虽然不是鸣谢，但公开文案仍会显得自我指涉。
- **建议**：改为“界面遵循项目内的 Ark 设计规范（`docs/design/`）”，或只描述设计语言。

---

## 6. 做得好的部分

- **进程执行安全**：所有 CLI 都通过 `QProcess` 程序+参数数组，无 shell 拼接；`tst_processrunner` 验证了危险参数不会被 shell 解释。
- **取消与超时**：Unix 独立进程组 + SIGTERM → 1.5s → SIGKILL；取消/超时测试通过。
- **隔离边界**：`CONFIG_DIR`/`CACHE_DIR`/`DATA_DIR`/`TEMP_DIR` 明确，`~/Hyps` 未被触碰；`git -C ~/Hyps` 状态干净。
- **组件克隆/更新**：临时目录 + 校验 + 原子 rename；脏工作区拒绝更新；只 fetch + ff-only，不 reset/clean；测试覆盖。
- **配置编辑**：保留注释/顺序，备份 + QSaveFile；多行/数组/重复键测试。
- **UI 修复**：About/诊断/设置改为 `Flickable` + 显式 contentHeight；CodeEditor 使用 Flickable + TextEdit + 常显滚动条；大窗口原始编辑器可用。
- **交付**：CTest 9/9、CI/Release 绿、安装包 + SHA256SUMS；文档明确真实游戏未验证、网络 E2E 禁用等限制。
- **设计资产**：无鹰角专有美术/字体文件；来源与许可在 `docs/credits.md` 记录。

---

## 7. 建议修复顺序

1. **P0（下一版前）**：F-01、F-02、F-03、F-04。
2. **P1（同版本或紧随）**：F-05、F-06、F-08、F-09、F-10、F-11。
3. **P1 工程化**：F-07、F-12、F-13、F-14。
4. **P2（清理）**：F-15～F-20。

**验收建议**

- 诊断包：以 `Authorization: Bearer ...`、`--token ...`、带凭据 URL 的样本做快照测试，导出后 grep 不到明文。
- 日志：100MB 日志下启动 < 1s，任务页按需加载；选中任务不阻塞 > 200ms。
- 并发：双实例同时保存同一配置，必须出现明确冲突提示，不能静默覆盖。
- 关闭：修改配置后关窗必须出现保存/放弃/取消。
- 发布：解包安装后 About 页 build commit 必须等于 tag 对应提交。

---

## 8. 未验证项

- 真实游戏启动（无已安装游戏）；Proton/umu 环境下的进程组、退出码和日志行为未实测。
- 真实 Wayland 合成器上的窗口位置/最大化恢复；截图使用 offscreen。
- 真实 D-Bus 通知守护进程；仅确认接口存在且无服务时静默降级。
- Release 包在干净 Arch 系统上的安装/运行（仅 CI makepkg 与本地构建验证）。
- `clang-tidy`/ASan/覆盖率未执行；本报告不宣称“无编译告警”。
- 未做性能基准；F-02/F-05 的耗时是静态推断，需用大日志实测确认。

---

## 9. 结论

Hyps Hub 已经是一个**可用的本地单用户 MVP**：执行层、隔离、克隆/更新、配置备份和视觉交付都明显高于一般原型。  
但它目前**不适合直接作为 1.0 广泛发布**：诊断脱敏承诺不成立、日志加载会卡启动、没有单实例保护、关闭会丢未保存配置，这四项都是用户可感知且可复现的 P0。

**MAGI 合议：有条件通过。** 修完 P0 并补上诊断/日志/关闭/并发回归测试后，可进入 RC；P1 完成后再考虑稳定版。
