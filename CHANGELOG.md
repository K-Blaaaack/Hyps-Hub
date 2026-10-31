# 变更记录

本文件记录每个发布版本的实际改动。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循语义化版本；`0.x` 阶段次版本号对应界面/契约层面的不兼容改动。

---

## [未发布]

### 变更

- **Release 正文改由 CHANGELOG 生成**：`.github/workflows/release.yml` 的 publish 作业先 checkout，
  用 `scripts/release-notes.sh <版本>` 抽出本版本段落作为正文，再补上完整变更记录与安装说明的链接。
  此前用 `generate_release_notes: true`，正文只有一行 `Full Changelog` 对比链接，对使用者没有信息量。
- 缺段落时发布流程直接失败（`CHANGELOG.md` 里没有对应 `## [版本]` 标题），避免发出正文空白的 release。
- `docs/development.md` §7 补发版要求与本地预览正文的方法。

---

## [0.4.0] — 2026-10-31

界面按 **Material Design 3** 全量重写。0.3.0 的 Ark 风格（近黑底 + 青色信号 + 45° 切角）
整体退役，改为 MD3 语义色板 + 组件层；顺带补上可自动化的界面自检工具链。

上游 Hyps 契约不变，仍对齐 `a2ac842`（基线 `1b94dc8`）。**配置文件格式、CLI 调用、任务历史均无破坏性变更**，
升级不需要迁移数据。

### 新增

**设计系统**

- `qml/theme/Md3.js` — MD3 令牌库：`shape`（none/extraSmall/small/medium/large/extraLarge/full）、
  `space`（xs 4 → xxxl 48）、`type`（15 级字阶）、`state`（悬停 8% / 按下 10% / 拖拽 16% / 禁用 38%）、
  `motion`（short2→long2 + 缓动曲线）、`size`、`elevation`，以及 `alpha/hover/pressed/focus/lineHeight` 等辅助函数。
- `src/app/thememanager.cpp` — 浅色 / 深色两套**完整** MD3 语义色板（surface 五档容器、primary/secondary/tertiary
  三组 on-色、outline、inverse、scrim），并扩展 `success` / `warning` 两组应用自定义语义色。
- `docs/design/MD3-SPEC.md` — 设计契约：颜色角色表、字阶表、形状/间距/状态/动效令牌、组件 API 清单、
  页面契约、Qt 6.10 已知限制与自检流程。实现以此为准，冲突时以本文档为准。

**组件层（46 个 `Md*` 组件）**

- 基础：`MdText`、`MdIcon`、`MdIconButton`、`MdButton`、`MdCard`、`MdDivider`、`MdTag`、`MdBadge`、`MdChip`
- 表单：`MdTextField`、`MdSearchField`、`MdField`、`MdPathField`、`MdFilePicker`、`MdSelect`、`MdSwitch`、
  `MdSwitchRow`、`MdCheckbox`、`MdRadioButton`、`MdSegmentedButton`
- 容器与结构：`MdNavRail`、`MdTopAppBar`、`MdDialog`、`MdConfirmDialog`、`MdRawEditorDialog`、`MdMenu`、
  `MdMenuItem`、`MdTooltip`、`MdSnackbar`、`MdExpansionPanel`、`MdSectionHeader`、`MdListItem`
- 数据与状态：`MdStatCard`、`MdInfoRow`、`MdTaskItem`、`MdLogView`、`MdCodeBlock`、`MdCodeField`、
  `MdValidationList`、`MdProgressLinear`、`MdProgressCircular`、`MdEmptyState`、`MdBanner`、`MdScrollBar`
- 品牌：`MdBrandMark` — 品牌字标，随主题自动切换深/浅色资源

**品牌资产**

- `assets/hyps-hub.svg` — 应用内标识（深色主题，透明底，`primary #d0bcff`）
- `assets/hyps-hub-light.svg` — 应用内标识（浅色主题，`primary #6750a4`）
- `assets/hyps-hub-tile.svg` — 自带底色的方形容器版，用于窗口图标与桌面入口

**自检工具链（`scripts/`）**

- `ui-fixture.sh` — 生成完全隔离的 XDG 夹具（含假组件、假运行器、假任务历史），截图与自检不读写真实配置
- `ui-audit.sh` — 全页几何审计：8 个页面 × 2 个窗口尺寸，报告 collapsed / overflow / clipped / NaN，
  并逐页渲染检查运行时警告
- `ui-geom.sh` — 逐控件绝对坐标转储（`类型|x|y|宽|高|文字`），用于排查 2–6px 级别的错位
- `qml-check.sh` — 单文件门禁：qmllint + 离屏加载 + 零 stderr
- `dev-run.sh` — 开发模式启动器：QML 走磁盘热重载，`src/`、`assets/`、`CMakeLists.txt` 变动自动增量编译重启
- `qml/dev/` — 审计页与组件画廊（`LayoutAudit` 及各 `Audit*Page`）

**文档与截图**

- `docs/screenshots/` — 10 张界面图（7 个主页面 + 引导页 + 两个弹窗），1440×900
- `docs/ui-review-2026-10-27.md` — 界面评审记录

### 变更

- **全部 8 个页面按 MD3 重写**：`HomePage`、`GamesPage`、`TasksPage`、`ConfigPage`、`DiagnosticsPage`、
  `SettingsPage`、`AboutPage`、`OnboardingPage`。统一 `property var host` 契约，单栏页内容宽
  `min(1100, 页宽 - 48)`、左轨固定 24；双栏页左右栏间距 16、页面边距 24/16。
- **应用外壳** `qml/Main.qml`：MD3 导航轨（80dp，含 56×32 选中指示器与徽标）+ 64dp 顶部应用栏
  （标题 + 英文副标题 + 右侧状态胶囊/按钮）+ `StackLayout` 页面栈 + Snackbar + 确认对话框。
- **主题管理** `ThemeManager`：`preference` 支持 `system` / `light` / `dark`，`dark` 与 `systemDark` 分离，
  跟随系统主题切换即时生效。
- **`MdText` 行高改为绝对像素**：`lineHeight: style.lineHeight` + `Text.FixedHeight`。
  此前用 `ProportionalHeight` 乘字体自然行高，每个文字块比规范高约 15%。
- **页面级卡片堆叠间距统一 24**（此前首页/游戏页右列用 16，诊断/设置/关于用 24）。
- **`MdBanner` 内边距 12 → 16**，与卡片内容同一条左轨。
- **README** 重写界面章节与截图，补充 MD3 设计系统说明。

### 修复

- **深色主题下所有状态层与半透明色失效**：`Theme.colors.*` 是 `QString`（`"#rrggbb"`）而非 `QColor`，
  直接取 `.r/.g/.b` 得到 `undefined`，`alpha()` 全部退化成黑色。新增 `channels()` 解析，
  修复禁用文字、滚动条、悬停/按下状态层。
- **嵌套 `ColumnLayout` 不撑满宽度**：内层 `Layout.fillWidth` 在部分嵌套下不生效，
  统一补 `Layout.maximumWidth: 100000`（40 处）。
- **`MdCard` 只测量第一个子项**，多子项卡片高度被压扁；改为按 `childCount` 汇总内容尺寸。
- **`MdStatCard` 说明文字被下边框裁切**：高度写死 108 而内容需要更多；改为由内容决定高度，
  左侧 4dp 状态色条上下内缩 10px，避免从 12dp 圆角里戳出来。
- **分段按钮选中胶囊盖住 1dp 描边**：胶囊贴边绘制，两端把外框描边整条盖掉；内缩 3dp，
  并按 MD3 规则隐藏紧邻选中段的分隔线。
- **表单「恢复默认」按钮导致 key 文字右轨参差**：按钮仅在键有默认值时显示，用 `visible: false`
  会让该行 key 顶到最右（979 vs 1092 差 113px）；改为 `opacity: 0` + `enabled: false` 保留占位。
- **`MdEmptyState` 圆底在同色容器里隐形**：弹窗底色与圆底同为 `surfaceContainerHigh`，
  只剩一个悬空小图标；`containerColor` 提为可配置属性，弹窗内改用 `surfaceContainerHighest`。
- **弹窗头部出现三条左边缘**：图标、说明、标题分属不同层级时说明会退回图标那条左轨；
  改为 `[图标][列(标题, 说明)][关闭]` 结构。
- **`MdInfoRow` 长路径按字符折行**：`WrapAnywhere` 会把路径从词中间断开；改为
  `NoWrap` + `ElideMiddle`，保留首尾可辨识部分。
- **浏览按钮只有 6px 高**：`Row` 定位器不处理子项 `anchors`，改用 `RowLayout` + `Layout.alignment`。
- **导航轨 `READY` 状态贴左边缘**：状态行误设 `width: root.width`，移除后居中。

### 移除

- **Ark 风格组件 26 个**：`ArkButton`、`ArkProgress`、`ArkTag`、`ChamferedPanel`、`CodeEditor`、`ConfigField`、
  `ConfirmDialog`、`EmptyState`、`FilePicker`、`GridBackdrop`、`InfoRow`、`LogView`、`MicroLabel`、`NavIcon`、
  `NavRail`、`PageHeader`、`PathField`、`RawEditorDialog`、`SectionHeader`、`StatCard`、`StripeRuler`、
  `TaskItem`、`ToggleRow`、`ToggleSwitch`、`TopBar`、`ValidationList`
- **纹理资源**：`assets/noise.png`、`assets/stripe.png`（Ark 风格的噪点与斜纹底）
- **旧截图**：`docs/screenshots/credits.png`

### 兼容性

| 项目 | 状态 |
| --- | --- |
| 配置文件（`config.json`、`hyps/games/*.conf`） | 无变更，可直接沿用 |
| 上游 Hyps 契约 | 仍对齐 `a2ac842`，无新增/删除字段 |
| 任务历史与日志格式 | 无变更 |
| 命令行参数 | 新增 `--qml-source`、`--screenshot`、`--smoke-test`、`--preview-dialog`、`--allow-root`（开发用），原有参数不变 |
| 桌面入口 | 图标改为自带底色的方形容器版，`.desktop` 的 `Icon=hyps-hub` 不变 |

### 验证

- `scripts/ui-audit.sh` — **PASS**：8 页面 × 2 尺寸，`collapsed=0 overflow=0 clipped=0 nan=0`；7 个页面渲染零警告
- `scripts/qml-check.sh` — 全部页面与组件通过（qmllint + 离屏加载 + 零 stderr）
- `ctest` — **11/11 通过**（`tst_network_e2e` 因需要外网默认禁用）
- 构建：Qt 6.12.0 + CMake + Ninja，软件渲染后端（`QT_QUICK_BACKEND=software`）下全部界面正常

---

## [0.3.0] — 2026-10-27

适配上游 Hyps `a2ac842`（基线 `1b94dc8`）：hosts 断网功能随上游移除、新增替身字段、弃用键告警。
`tst_configmanager` 新增 15 个用例。详见 [docs/upstream-sync-2026-10-27.md](docs/upstream-sync-2026-10-27.md)。

## [0.2.0] — 2026-10-19

首个可用版本：游戏配置编辑、任务执行与日志、诊断与环境报表、配置管理、原始编辑器。

[0.4.0]: https://github.com/K-Blaaaack/Hyps-Hub/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/K-Blaaaack/Hyps-Hub/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/K-Blaaaack/Hyps-Hub/releases/tag/v0.2.0
