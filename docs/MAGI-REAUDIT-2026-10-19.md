# MAGI 复审：Hyps Hub 修复后复核

> 复审对象：`/home/kb/github/Hyps-Hub` 工作区（基于 `6b12734` / v0.1.7 的审查修复）  
> 复审日期：2026-10-19  
> 复审方式：MELCHIOR（正确性/可靠性）、BALTHASAR（安全/隐私/隔离）、CASPER（产品/可维护性/交付）三席复核。  
> 说明：本轮未发布新 tag/Release；以下结论基于工作区构建、11 项 CTest 与静态复核。

---

## 0. 复审裁决

| 席位 | 结论 | 说明 |
| --- | --- | --- |
| MELCHIOR | **通过（RC 级）** | 4 项 P0 全部落地；日志懒加载/尾部截断、单实例、关闭保护、脱敏边界均有代码/测试证据。剩余主要是 UI 自动化缺失。 |
| BALTHASAR | **有条件通过** | 诊断脱敏、Git 环境净化、发布源校验已修复；Actions 仍用浮动 tag、Arch 镜像未固定、发布未签名，属于发布链残余风险。 |
| CASPER | **有条件通过** | 截图已回到 1440×900/0.1.7，文档术语与安装清单更新；仍未做完整 WCAG，QML 键盘/关闭流程无自动化，`credits.png` 孤立文件仍在。 |
| **合议** | **有条件通过（RC-ready）** | **可以进入 RC/手动验收；不建议直接宣布 1.0。** |

**RC 前必须人工验证：** 双实例、关闭未保存配置、原始编辑器关闭确认、真实 Git 更新、发布包 build commit、root 拒绝/`--allow-root`。

---

## 1. 本轮修复对照

| ID | 原问题 | 本轮处理 | 状态 |
| --- | --- | --- | --- |
| F-01 | 诊断脱敏覆盖不足 | 新增私钥块、URL userinfo、Authorization/Bearer、`--token`、引号/JSON 值规则；新增多格式测试 | **已修复** |
| F-02 | 启动同步读完整日志 | 启动只载元数据；任务页可见/选中时才加载；只读尾部 2 MiB、最多 5000 行、单行 32 KiB；新增 `tst_taskmanager` | **已修复** |
| F-03 | 无单实例锁 | `QLockFile`（state 目录，30s stale）；第二实例提示后退出；同时拒绝 root 并发写 | **已修复，需人工验证提示** |
| F-04 | 关闭丢未保存配置 | `ConfigManager::hasUnsavedChanges()`；`onClosing` 弹确认；RawEditorDialog 关闭/Esc 确认；`Ctrl+S` 不受确认框干扰 | **已修复，需人工验证** |
| F-05 | 诊断读前 8MB/同步 80MB | 改为从尾部读 512 KiB；最多 10 个任务日志；`QSaveFile` 原子写；新增 >512KB 尾部测试 | **已修复（同步但有界）** |
| F-06 | 发布包 build commit 为 unknown | CMake 读取 `HYPS_HUB_GIT_COMMIT` 环境；Release 传 `GITHUB_SHA[:12]`；源码 tar 使用实际 SHA256 | **代码已修复，未跑 Release 验证** |
| F-07 | Git 继承 GIT_*、未禁钩子 | 清理 `GIT_DIR/GIT_CONFIG_*/GIT_SSH_COMMAND/...`；固定 `core.hooksPath=/dev/null`、remote.origin.url；禁全局/系统配置 | **已修复；真实 fetch 未跑** |
| F-08 | 写诊断文件忽略 write 失败 | 检查写入字节、`commit()`；失败返回错误 | **已修复** |
| F-09 | 日志无上限/清历史不删日志 | 任务日志保留 200；清历史删对应日志；runtime log 2 MiB 轮转；更新历史保留 200 | **已修复** |
| F-10 | 带连字符配置无法编辑 | `gameConfig`/create 允许 `-`；GameCatalog 只列合法 slug；新增 `tst_configmanager` | **已修复** |
| F-11 | 隐藏诊断页启动即联网 | 改为 `visible` 后才检查；隐藏时不发请求 | **已修复** |
| F-12 | 导航/任务行键盘不可达 | NavRail/TaskItem/ToggleSwitch 增加 focus、Keys、Accessible；CodeEditor 增加 role/name | **部分修复**（无完整 WCAG/字体缩放） |
| F-13 | 测试/告警门禁不足 | 新增 TaskManager/ConfigManager 测试；`-Wall -Wextra -Wpedantic`；当前构建 0 warning；11/11 CTest | **部分修复**（无 QML UI/ASan） |
| F-14 | 发布链未固定/无签名 | Release 源 tar 使用真实 SHA256；build commit 传入；Actions 仍用 major tag、Arch 仍 latest、无签名 | **部分修复** |
| F-15 | 文档/截图漂移 | 重新生成 1440×900/0.1.7 全部页面截图；术语与安装清单更新；`credits.png` 删除被 MAGI 拦截 | **大部分修复，1 个孤立文件残留** |
| F-16 | PKGBUILD URL 指错 | 改为 `K-Blaaaack/Hyps-Hub`；AppStream 尚未补 | **部分修复** |
| F-17 | 窗口几何可能出屏 | 非截图模式按 `Screen.desktopAvailableWidth/Height` 收敛；截图模式保留 1440×900 | **已修复** |
| F-18 | System/stdout 共用缓冲、长行 O(n²) | 3 个独立 partial；System 独立写；64 KiB 行截断；LogModel 同步限长 | **已修复** |
| F-19 | root 只提示不阻止 | 默认拒绝 root，`--allow-root` 仅调试；CTest smoke 显式加 `--allow-root` 以适配 CI root 容器 | **已修复** |
| F-20 | 关于页“用户提供”残留 | 改为“项目内的 Ark 设计规范（docs/design）” | **已修复** |

---

## 2. 证据

### 构建与测试

- `cmake --build build -j4`：成功；**0 warning**（启用 `-Wall -Wextra -Wpedantic`；Qt 的 `-Wsfinae-incomplete` 已在 CMake 中说明并抑制）。
- `ctest --test-dir build --output-on-failure`：**11/11 passed**。
  - `tst_network_e2e`：默认禁用。
  - 新增：`tst_taskmanager`、`tst_configmanager`。
  - `tst_smoke` 现在使用 `--smoke-test --allow-root`，避免 CI/Arch 容器 root 环境被新的 root 保护误伤。
- 截图：全部为 **1440×900**，页脚 0.1.7；已更新 About/主页/任务/诊断/设置/编辑器等。

### 关键代码位置

- 脱敏：`src/diagnostics/diagnostics.cpp:42-91`
- 尾部读取：`src/diagnostics/diagnostics.cpp:93-125`
- 原子写入：`src/diagnostics/diagnostics.cpp:127-160`
- 懒加载/尾部：`src/app/taskmanager.cpp:555-725`
- 单实例/root：`src/main.cpp:72-105`
- 关闭保护：`qml/Main.qml:122-130`、`qml/Main.qml:250-275`
- Git 环境：`src/runtime/runtimemanager.cpp:38-105`
- 截断/轮转：`src/runtime/runtimemanager.cpp:188-310`

---

## 3. 仍需关注（RC 前）

1. **F-03/F-04 需要真人 UI 验证**：双实例提示、关闭含 dirty 配置、RawEditor 放弃确认，均没有自动化点击测试。
2. **F-06/F-14 没有实际 Release 验证**：本轮未打 tag；需用 `git archive` → makepkg 构建一次，检查 About build commit 与 `SHA256SUMS`。
3. **F-07 的真实网络更新未跑**：fake git 测试通过，但真实 `git fetch/merge` 在净化环境下的 HTTPS 行为需要网络 E2E 手工确认。
4. **F-05 仍是同步导出**：已把 80MB 风险降到最多约 5MB，但极端慢盘仍可能短暂卡 UI。
5. **F-12 非完整无障碍**：键盘导航/角色已补，仍无字体缩放、完整 WCAG 与屏幕阅读器验证。
6. **F-14 未完成**：Actions 仍为 `@v7/@v8/@v3`，`archlinux:latest` 未固定 digest，Release 无签名；受当前工具/凭据限制，未伪造完成。
7. **F-15 残留**：`docs/screenshots/credits.png` 仍被 Git 跟踪但 README 未引用；删除操作被 MAGI 升级为人工决定，未执行。
8. **CI root 兼容**：已为 `tst_smoke` 添加 `--allow-root`；若未来 CI 改为非 root，参数仍无害。

---

## 4. 结论

本轮把第一份审查中的 **4 项 P0 全部关闭**，P1 的大部分关闭，P2 大部分关闭；构建无告警、11/11 CTest 通过、截图恢复到 0.1.7/1440×900。  
剩余风险集中在**未自动化的 UI 行为、未实际执行的 Release/Git 网络链路、发布链签名/固定**，这些属于“需要人工验收/发布工程”的残余，而不是当前代码的阻塞缺陷。

**MAGI 复审：有条件通过，RC-ready。** 建议先按第 3 节完成人工验收，再决定是否打 tag；在完成 Release 验证前不要标记稳定版。
