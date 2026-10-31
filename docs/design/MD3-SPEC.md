# MD3 界面规范（本项目的实现契约）

本文件是「Hyps Hub 全量 MD3 重写」的唯一契约。所有页面与组件都必须按此实现，
不再使用旧的 Ark 设计语言（近黑墨底、0 圆角、45° 切角、噪点/警戒线纹理）。

## 1. 硬约束

1. **只用令牌**：颜色一律 `Theme.colors.<role>`；字号一律 `Md3.type.<role>`；
   圆角一律 `Md3.shape.*`；间距一律 `Md3.space.*`；时长一律 `Md3.motion.*`。
   **禁止**出现十六进制色值、`font.pixelSize: 13` 这类自造字号、`radius: 0`。
2. **禁止旧令牌**：`Theme.colors.ink / ink2 / ink3 / ink4 / rule / line / lineHover /
   paper / paper2 / muted / disabled / signal / signalPressed / onSignal / state /
   warn / danger / scrollbar / topBar / gridLine / stripe / vignette` 全部作废。
   对应新角色见第 2 节。
3. **禁止旧组件**：`ArkButton / ArkTag / ArkProgress / ChamferedPanel / GridBackdrop /
   StripeRuler / MicroLabel / NavIcon / NavRail / TopBar / PageHeader / ToggleRow /
   ToggleSwitch / ConfigField / PathField / FilePicker / RawEditorDialog / CodeEditor /
   LogView / TaskItem / InfoRow / ValidationList / StatCard / EmptyState / ConfirmDialog /
   SectionHeader` 全部由 `Md*` 组件替代。
4. **每个可交互元素都要有**：hover 状态层（8%）、pressed（10%）、键盘焦点环、
   `Accessible.role` / `Accessible.name`、`cursorShape: Qt.PointingHandCursor`。
5. **QML 必须零运行时警告**：`scripts/qml-check.sh` 通过才算完成。

## 2. 颜色角色（C++ `ThemeManager::colors()`）

MD3 官方 baseline scheme，浅/深两套，跟随系统或手动切换。

| 分组 | 角色 |
| --- | --- |
| Primary | `primary` `onPrimary` `primaryContainer` `onPrimaryContainer` |
| Secondary | `secondary` `onSecondary` `secondaryContainer` `onSecondaryContainer` |
| Tertiary | `tertiary` `onTertiary` `tertiaryContainer` `onTertiaryContainer` |
| Error | `error` `onError` `errorContainer` `onErrorContainer` |
| Success（扩展） | `success` `onSuccess` `successContainer` `onSuccessContainer` |
| Warning（扩展） | `warning` `onWarning` `warningContainer` `onWarningContainer` |
| Surface | `surface` `onSurface` `surfaceDim` `surfaceBright` `surfaceContainerLowest` `surfaceContainerLow` `surfaceContainer` `surfaceContainerHigh` `surfaceContainerHighest` `onSurfaceVariant` |
| Outline | `outline` `outlineVariant` |
| Inverse | `inverseSurface` `inverseOnSurface` `inversePrimary` |
| 其它 | `scrim` `shadow` `codeSurface` `dark`（bool） |

用法约定：

- 页面底：`surface`；一级卡片：`surfaceContainerLow`；卡片内嵌区块：`surfaceContainer`；
  输入框/列表悬停：`surfaceContainerHighest`。
- 正文 `onSurface`，次要文字 `onSurfaceVariant`，分割线 `outlineVariant`，描边 `outline`。
- 主操作 `primary`，次操作 `secondaryContainer`，危险 `error`。

## 3. 排版（`Md3.type`）

| 角色 | 字号/行高 | 用途 |
| --- | --- | --- |
| `displayLarge/Medium/Small` | 57/45/36 | 首启引导的大标题 |
| `headlineLarge/Medium/Small` | 32/28/24 | 页面内区块大标题 |
| `titleLarge/Medium/Small` | 22/16/14 | 顶部应用栏、卡片标题 |
| `bodyLarge/Medium/Small` | 16/14/12 | 正文、说明 |
| `labelLarge/Medium/Small` | 14/12/11 | 按钮、标签、状态胶囊 |

等宽场景（日志、配置键、路径、代码）用 `Md3.mono.*` 或 `MdText { mono: true }`，
字体族固定 `App.monoFontFamily`。

## 4. 形状 / 间距 / 状态 / 动效

- `Md3.shape`：`none 0` `extraSmall 4` `small 8` `medium 12` `large 16` `extraLarge 28` `full`
  （胶囊用 `height / 2`，`Md3.pill(h)`）。
- `Md3.space`：`none 0` `xxs 2` `xs 4` `sm 8` `md 12` `lg 16` `xl 24` `xxl 32` `xxxl 48`。
  页面外边距 24，卡片内边距 16，卡片间距 16，区块间距 24。
- `Md3.state`：`hover .08` `focus .10` `pressed .10` `dragged .16`
  `disabledContent .38` `disabledContainer .12`。
- `Md3.motion`：`short2 100` `short3 150` `short4 200` `medium2 300` `medium3 350` `long2 500`。
  进场 `Easing.OutCubic`，退场 `Easing.InCubic`，尺寸变化 `Easing.InOutCubic`。
- `Md3.size`：`button 40` `iconButton 40` `chip 32` `textField 56` `listItem 56/72/88`
  `navRail 80` `topAppBarSmall 64` `switchTrackWidth 52` `switchTrackHeight 32`。

## 5. 组件清单（`qml/components/Md*.qml`）

属性名是**冻结契约**，实现时不得改名（其它页面已按此调用）。

| 组件 | 关键 API |
| --- | --- |
| `MdIcon` | `name` `size` `color` `strokeWidth` `filled`（已实现，图标名见文件内 switch） |
| `MdBrandMark` | `markSize`；品牌字标（单个 H），颜色随主题自动切换 |
| `MdText` | `role` `mono` `tone`(`default/variant/primary/error/success/warning/inverse`) `strong` |
| `MdButton` | `text` `variant`(`filled/tonal/outlined/text/elevated`) `iconName` `danger` `clicked()` |
| `MdCard` | `variant`(`filled/elevated/outlined`) `cornerRadius` `padding` `interactive` `selected` `clicked()` |
| `MdTextField` | `text` `label` `placeholderText` `supportingText` `error` `variant` `leadingIcon` `trailingIcon` `trailingText` `monospace` `compact` `accepted()` `editingFinished()` `textEdited(text)` |
| `MdNavRail` | `currentPage` `pages[{id,label,icon}]` `badges{}` `expanded` `runtimeReady` `version` `navigate(id)` |
| `MdTopAppBar` | `title` `subtitle` `iconName` `scrolledUnder` + 默认属性槽 `actions` |
| `MdIconButton` | `iconName` `variant`(`standard/filled/tonal/outlined`) `size` `iconSize` `danger` `tooltip` `clicked()` |
| `MdFab` | `iconName` `text` `size`(`small/regular/large`) `variant`(`primary/secondary/tertiary`) `clicked()` |
| `MdTag` | `text` `status`(`neutral/primary/success/warning/error/tertiary`) `iconName` `outlined` |
| `MdChip` | `text` `variant`(`assist/filter/input/suggestion`) `selected` `iconName` `status` `removable` `clicked()` `removed()` |
| `MdBadge` | `text` `dot` `status` |
| `MdSwitch` | `checked` `toggled(bool)` |
| `MdSwitchRow` | `title` `description` `checked` `enabled` `toggled(bool)`；整行可点，开关靠右 |
| `MdCheckbox` | `checked` `indeterminate` `text` `toggled(bool)` |
| `MdRadioButton` | `checked` `text` `value` `toggled(bool)` |
| `MdSegmentedButton` | `model[{value,text,iconName}]` `currentValue` `size` `activated(value)` |
| `MdProgressLinear` | `value`(-1=不确定) `thickness` `color` |
| `MdProgressCircular` | `value` `size` `thickness` `color` |
| `MdEmptyState` | `iconName` `title` `description` `actionText` `actionClicked()` |
| `MdBanner` | `text` `status`(`info/success/warning/error`) `actionText` `closable` `actionClicked()` `closed()` |
| `MdSelect` | `label` `model[{value,text}]` `currentValue` `supportingText` `placeholder` `compact` `activated(value)` |
| `MdMenu` / `MdMenuItem` | 菜单容器 / `text` `iconName` `destructive` |
| `MdDialog` | `heading` `iconName` + 默认内容槽 + `actions` 槽，`open()/close()` |
| `MdConfirmDialog` | `heading` `message` `confirmText` `cancelText` `danger` `accepted()` `rejected()` |
| `MdSnackbar` | `message` `actionText` `show(text)` `actionTriggered()` |
| `MdListItem` | `headline` `supporting` `leadingIcon` `trailingText` `trailingIcon` `status` `selected` `interactive` `clicked()` |
| `MdSectionHeader` | `title` `caption` `iconName` + 默认属性槽 `trailing` |
| `MdDivider` | `inset` `vertical` |
| `MdInfoRow` | `label` `value` `mono` `copyable` `copyRequested()` |
| `MdCodeField` | `text` `label` `placeholderText` `readOnly` `minHeight` `wrapMode` |
| `MdCodeBlock` | `text` `maxHeight` `wrap` |
| `MdRawEditorDialog` | `heading` `subtitle` `initialText` `readOnly` `openWith(text)` `applyText(text)` `applyAndSave(text)` |
| `MdField` | `config` `configKey` `title` `description` `hint` `type`(`text/int/bool/enum/array/file/dir/runner`) `options` |
| `MdPathField` | `text` `label` `placeholder` `mode`(`file/dir`) `nameFilter` `dialogTitle` `committed(path)` |
| `MdFilePicker` | `mode` `startPath` `nameFilter` `dialogTitle` `selected(path)` |
| `MdLogView` | `logModel` `title` `busy` `autoScroll` |
| `MdTaskItem` | `taskId` `label` `stateText` `kind` `durationText` `errorSummary` `active` `selected` `clicked()` |
| `MdValidationList` | `issues[{level,message}]` `emptyText` |
| `MdScrollBar` | ScrollBar 子类，直接用于 `ScrollBar.vertical: MdScrollBar {}` |
| `MdExpansionPanel` | `title` `subtitle` `iconName` `expanded` `toggled(bool)` + 默认内容槽 |
| `MdSearchField` | `placeholder` `text` `edited(text)` `accepted()` |
| `MdStatCard` | `label` `value` `caption` `status` `iconName` |

### 5.1 品牌资产（`assets/`）

| 文件 | 用途 | 底色 |
| --- | --- | --- |
| `hyps-hub.svg` | 应用内标识（深色主题），`MdBrandMark` 自动选用 | 透明 |
| `hyps-hub-light.svg` | 应用内标识（浅色主题），`MdBrandMark` 自动选用 | 透明 |
| `hyps-hub-tile.svg` | 窗口图标 + 安装到 hicolor（`.desktop` 的 `Icon=hyps-hub` 命中它） | 自带 `#211f26` 圆角方 |

标识是**单色 H 字标**，只取 MD3 的 `primary`：深色 `#d0bcff`，浅色 `#6750a4`。
不带任何装饰点或第二个色相——字标在 16–128px 全尺寸下都要成立，附加元素只会先糊掉。
**不要**在 QML 里硬写 `qrc:/assets/hyps-hub.svg`，一律用 `MdBrandMark`，否则浅色主题会拿到
为深底设计的浅紫，在浅底上对比度不够。

安装时只装 tile 版并 `RENAME hyps-hub.svg`：桌面图标必须自带底色，透明底标压在任意壁纸上都会糊。

## 6. 页面契约

每个 `qml/pages/*.qml` 的根都是 `Item`：

```qml
Item {
    id: page
    property var host          // Main 窗口：host.navigate("tasks") / host.showToast("…")
}
```

- **不要**在页面里再画一级标题（顶部应用栏已显示页面标题）。
- 页面整体结构：`Flickable`（或 `ScrollView`）包一个 `ColumnLayout`，
  左右 24 边距、上 16、下 32，`spacing: 24`。
- **统一栅格（所有页面共用，切页时左边缘不许跳）**：
  - 单栏页（首页/配置/诊断/设置/关于）：
    `width: Math.min(1100, page.width - Md3.space.xl * 2); x: Md3.space.xl`，**左对齐不居中**。
  - 双栏页（游戏/任务）：整页铺满（左右 24 边距），左栏固定宽度
    （游戏 300 / 任务 340），且**左栏标题栏放进左栏面板内部**——标题行摆在面板上方时，
    左栏顶边会比右栏低一整行。
  - 卡片内边距统一 `MdCard.padding`（16），卡片内所有内容（区块标题文字、字段、
    信息行、分割线）都从这 16 起排；**区块标题不要带图标**，图标会把标题文字推到
    42px，和正文的 16px 左轨错开。
- 长列表/长表单必须可滚动；`ScrollBar.vertical: MdScrollBar { }`。
- 空态用 `MdEmptyState`；错误/提醒用 `MdBanner`；确认用 `MdConfirmDialog`；
  反馈用 `host.showToast(...)`。
- 所有按钮的可用性由真实状态驱动（`Runtime.ready`、`Configs.hasUnsavedChanges()`、
  `Tasks.activeCount` 等），不要出现点了没反应的按钮。

## 7. Qt 6.10 已知限制（踩过，别再踩）

1. `TextField`/`TextArea` **不能覆写 `contentItem`**（运行时报 non-existent property）。
   需要自定义外观时用 `FocusScope/Item + TextInput/TextEdit` 自己拼（见 `MdTextField`）。
2. `T.Button` 的 `icon`、`T.Dialog` 的 `title` 是 **FINAL** 属性，不能重名声明
   → 本项目统一用 `iconName`、`heading`。
3. `Popup`/`Dialog` 不支持 `anchors`，只能用 `x/y` 定位（`MdSnackbar` 由 Main 用 x/y 摆放）。
4. `Rectangle` 没有分角圆角（`topLeftRadius` 需 Qt ≥ 6.7 且本机未验证），
   胶囊/圆角统一用 `radius` 单值。
5. 截图/测试跑在 `QT_QUICK_BACKEND=software` 下：**不要用** `MultiEffect`、
   `DropShadow`、`layer.effect`、粒子等需要 GPU 的效果。阴影用半透明 `Rectangle` 近似。
6. Canvas 图标（`MdIcon`）在软件后端可用；新增图标名请加进 `MdIcon.qml` 的 `switch`。
7. **全宽组件必须在根上写 `Layout.fillWidth: true`。** `ColumnLayout` 里没写这行的子项
   宽度取 `implicitWidth`；根是 `Item` 且没给 `implicitWidth` 时宽度就是 **0** —— 内容不会报错，
   只是悄悄不显示（`MdSectionHeader`/`MdInfoRow` 曾因此整块空白）。
   全宽组件清单：`MdSectionHeader`、`MdInfoRow`、`MdListItem`、`MdTaskItem`、`MdField`、
   `MdPathField`、`MdCodeField`、`MdCodeBlock`、`MdLogView`、`MdValidationList`、
   `MdEmptyState`、`MdBanner`、`MdProgressLinear`、`MdDivider`（横向时）。
   同时给一个 `implicitWidth`（240–320）兜底，供非 Layout 父级（`Column`/`Item`）使用。
8. **不要用 `childrenRect` 算 `implicitWidth/Height`。** 子项靠 `anchors.fill` 摆放时
   `childrenRect` 是 0，卡片会被压成一条边（`MdCard` 踩过）。取首个子项的
   `implicitWidth/Height` 相加 padding。
9. `Layout.preferredWidth` **不是**固定宽度：同一 `RowLayout` 里有 `Layout.fillWidth` 的兄弟时
   会被挤掉。固定侧栏要三件套一起写：`preferredWidth` + `minimumWidth` + `maximumWidth`。
10. **嵌套布局当 `Layout.fillWidth` 子项时，必须显式给 `Layout.maximumWidth`。**
    `ColumnLayout`/`RowLayout` 的 `maximumWidth` 由子项推导：子项全是按内容取宽
    （`MdText`、按钮）时，它自己的上限就等于内容宽，于是 `Layout.fillWidth` **不生效**，
    父布局剩下的空间全空着。典型症状：`设置 → 主题` 的分段按钮挤在标题右边、
    右边一大片空白。写法：

    ```qml
    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 100000   // ← 关键：解除子项推导出的上限
    }
    ```

    替代写法（更好读）：把行做成 `Item { Layout.fillWidth: true }` + 左右锚定，
    参考 `MdSwitchRow`。**不要**用「`MdListItem` 里塞 `MdSwitch`」——`MdListItem` 的正文是
    绝对定位的，塞进去的子项会落在 (0,0) 和标题重叠。
11. `Theme.colors.*` 是 `QVariantMap` 里的 **字符串**（`"#rrggbb"`），不是 `QColor`。
    直接 `color.r` 是 `undefined`，`Qt.rgba(...)` 会得到**黑色**。要带透明度请走
    `Md3.alpha(color, a)`（已支持字符串）或 `Md3.hover/pressed/disabledContent`，
    不要在组件里手写 `Qt.rgba(color.r, ...)`。踩过的现象：禁用按钮文字和卡片同色（看不见）、
    滚动条滑块全黑（看不见）。
12. **卡片正文只放一个 `ColumnLayout`。** `MdCard` 按「单个子项取它的 `implicitHeight`，
    多个子项按堆叠累加」算尺寸；正文散着放多个兄弟项时高度会算少，内容溢出到卡片边框外
    （`诊断页` 空态按钮穿出卡片就是这个）。
14. **行高要用绝对像素（`Text.FixedHeight`），不是倍率。** MD3 的 `lineHeight` 是
    「headlineMedium = 36px」这种绝对值；用 `Text.ProportionalHeight` 再乘一遍字体自然行高，
    每个文字块会比规范高 15% 左右，所有「按文字高度算」的卡片/行距都跟着虚胖
    （`MdStatCard` 曾因此把说明文字顶出下边框）。`MdText` 统一：
    `lineHeight: style.lineHeight; lineHeightMode: Text.FixedHeight`。
15. **圆角容器里的直条/贴边色块要内缩。** 卡片左侧 4dp 状态色条如果 `anchors.fill` 到
    上下边，直条会从圆角里戳出来（12dp 圆角、放大一眼可见方角）。上下各让开
    `shape.medium - 2`。同理分段按钮的选中胶囊要内缩 3dp，否则贴着 1dp 描边画，
    描边在两端被盖掉，看起来像胶囊从外框里溢出来。
16. **`mapToItem` 对带 `rotation` 的项不可信。** `MdIcon` 的 chevron 用 `rotation: 180`
    做展开态，几何转储里它的 y 会整体偏一个自身高度，看着像「图标跑到标题下面」。
    这类项一律以截图像素为准。
17. **同一列表里「有按钮」和「没按钮」的行要用占位对齐。** `MdField` 的「恢复默认」
    只在键存在时显示，直接 `visible: false` 会让这一行的 key 文字顶到最右，
    和上下行错开一截；改成 `opacity: 0` + `enabled: false` 保留位置。
18. **弹窗里放 `MdEmptyState` 要换圆底色。** 它的图标圆底默认 `surfaceContainerHigh`，
    而弹窗底色也是 `surfaceContainerHigh` —— 圆底直接消失，只剩一个悬空的小图标。
    传 `containerColor: Theme.colors.surfaceContainerHighest`。
19. **弹窗头部「图标 + 标题 + 说明」要做成一列。** 图标和标题是同级 `RowLayout` 子项时，
    下面的说明会退回图标那条左轨，出现「图标 476 / 说明 490 / 标题 506」三条左边缘。
    正确写法：`RowLayout[ MdIcon, ColumnLayout[标题, 说明], 关闭按钮 ]`。
20. **图标底板不要用固定表面色**——它总会和某一处背景同色而隐形。品牌头卡片是
    `filled`（`surfaceContainerHighest`），引导页背景是 `surface`：底板取 `surfaceContainerHighest`
    在卡片里看不见，取 `surface` 在引导页看不见，取 `primaryContainer` 在浅色主题下又几乎和
    白色卡片同色。结论是**别加底板**，标识本身已按主题配色，直接压在背景上对比度就够。
    （同一条规律的第 3 个实例：`MdEmptyState` 的圆底在弹窗里隐形。）
21. `MdEmptyState` 不要在外面压 `Layout.preferredHeight`：它是垂直居中的，
    高度小于内容时上下同时溢出，动作按钮会跑出卡片。让它自己撑开即可。

## 8. 自检流程（每个文件都要跑）

```bash
scripts/qml-check.sh qml/components/MdButton.qml          # 语法 + 真实加载 + stderr 零警告
scripts/qml-check.sh qml/dev/CoreGallery.qml --shot       # 组件画廊 + 截图像素摘要
scripts/ui-audit.sh                                       # 全页几何审计 + 运行时警告门禁
scripts/ui-geom.sh ConfigPage > /tmp/geom.txt             # 逐控件绝对坐标转储（对轨用）
```

`ui-geom.sh` 输出 `类型|x|y|宽|高|文字`，用来查「差 2–6px」这类肉眼难判的错位：
把同一页所有 key 文字的 `x+宽` 排序，就能看出它们的右轨是不是同一条；
把同一行按钮的 `高` 排序，就能看出谁被压扁了。注意坐标是「页面内」的
（不含导航轨 80 和顶部栏 64），截图坐标 = 转储坐标 + (80, 64)。

`scripts/ui-audit.sh` 是**回归主力**：它用 `qml/dev/LayoutAudit.qml` 遍历每页对象树，报告
`COLLAPSED`（可见却 0 尺寸）/`OVERFLOW`（超出窗口）/`CLIPPED`（文本被截断）/`NAN`，
在 1440×900 与最小窗口 1040×720 下各跑一遍，再用 qrc 构建逐页渲染卡运行时警告。
每页的入口是 `qml/dev/Audit<Page>.qml` 与 `qml/dev/AuditNarrow<Page>.qml`。

⚠️ 本进程**吞掉 QML 的 `console.*`**（`console.log/warn/error` 都不落 stderr），
只有引擎级警告（`TypeError`、`createQmlObject` 失败等）会打印。审计结果因此靠
「故意让 `Qt.createQmlObject` 失败、把文本塞进 import 名」这条通道带出来，
且必须**未捕获**才会打印 —— 一次只能发一条，`LayoutAudit.qml` 用 1ms 定时器逐条抛。
写新的 dev 探针时照抄 `LayoutAudit.qml` 的 `emitOne()` / `report()`。

判断 QML 属性是否存在要用 `x.prop !== undefined`，**不能**用 `hasOwnProperty`
（QML 属性挂在原型上，`hasOwnProperty` 恒为 false，会让检查静默失效）。

组件画廊放在 `qml/dev/`（不进 qrc），根用 `ApplicationWindow`，
背景 `Theme.colors.surface`，把组件的所有变体/状态排开展示。

页面自检：

```bash
scripts/ui-fixture.sh /tmp/md3-fixture     # 一次性
XDG_CONFIG_HOME=/tmp/md3-fixture/config XDG_DATA_HOME=/tmp/md3-fixture/data \
XDG_STATE_HOME=/tmp/md3-fixture/state XDG_CACHE_HOME=/tmp/md3-fixture/cache \
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
build/hyps-hub --qml-source qml/Main.qml --screenshot /tmp/shot.png --allow-root
```

## 9. 完成定义（DoD）

- 组件：所有声明的变体/状态都实现；有 hover/pressed/focus；无硬编码色值；无 QML 警告；
  全宽组件根上有 `Layout.fillWidth: true`（见 §7.7）。
- 页面：功能与旧页面等价或更强（校验、备份、错误提示、空态、加载态齐全）；
  可滚动、无裁切；小窗口 1040×720 与大窗口 1440×900 都不溢出。
- 合入前：`scripts/ui-audit.sh` 输出 `PASS`（两种尺寸 × 8 页，四项计数全 0），
  `ctest` 全绿，`docs/screenshots/` 用当前构建重出。
- 提交：只改自己负责的文件；不碰 `qml/Main.qml`、`qml/theme/`、`CMakeLists.txt`。
