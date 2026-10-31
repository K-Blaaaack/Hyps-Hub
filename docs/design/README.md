# 设计系统

界面遵循 **Material Design 3（MD3）**，实现位于 `qml/theme/Md3.js`（令牌）与
`qml/components/Md*.qml`（组件）；C++ 侧的语义色板在 `src/app/thememanager.cpp`。

## 当前文档

- `MD3-SPEC.md`：**唯一契约**。颜色角色、字阶、形状、间距、状态层、动效、组件 API、
  页面契约、Qt 6.10 限制与自检命令都在这里。

## 结构

| 层 | 位置 | 说明 |
| --- | --- | --- |
| 颜色 | `src/app/thememanager.cpp` | 基线紫配色，浅/深两套完整语义角色（含自定义 `success` / `warning`） |
| 令牌 | `qml/theme/Md3.js` | `shape` / `space` / `type` / `state` / `motion` / `size` / `elevation` |
| 组件 | `qml/components/Md*.qml` | 46 个组件，API 冻结，页面只通过它们拼装界面 |
| 页面 | `qml/pages/*.qml` | 7 个主页面 + 引导页，统一 `property var host` 契约 |
| 外壳 | `qml/Main.qml` | 导航轨 + 顶部应用栏 + StackLayout + Snackbar/确认对话框 |

## 关键约定

1. 只使用 MD3 语义色（`Theme.colors.primary`、`surfaceContainerHigh`、`onSurfaceVariant`…），
   不在 QML 里写死色值。
2. 字号只用 15 级字阶（`MdText { role: "bodyMedium" }`），不写 `font.pixelSize`。
3. 圆角只用 `Md3.shape.*`，间距只用 `Md3.space.*`，动效只用 `Md3.motion.*`。
4. 交互态用状态层（悬停 8%、按下 10%、拖拽 16%、禁用 38%），不改文字颜色。
5. 软件渲染（`QT_QUICK_BACKEND=software`）下不使用 shader 效果；阴影用偏移半透明矩形近似。
6. 图标统一走 `MdIcon`（Canvas 自绘 24×24 线性图标），不引入图标字体。
7. 品牌标识统一走 `MdBrandMark`（`assets/hyps-hub{,-light}.svg`，随主题切换）；
   窗口图标与桌面入口用自带底色的 `assets/hyps-hub-tile.svg`。

## 历史归档

`ARK-STYLE-GUIDE.md` 与 `视觉设计白皮书.md` 是早期 Ark 风格界面的规范与踩坑记录，
仅作历史参考，**不再作为实现依据**；对应组件（`ArkButton`、`ChamferedPanel`、`GridBackdrop` 等）
与纹理资源已从仓库移除。

## 自检

```bash
scripts/qml-check.sh qml/components/MdButton.qml     # 单文件：qmllint + 离屏加载 + 像素摘要
scripts/qml-check.sh qml/pages/HomePage.qml
scripts/ui-fixture.sh /tmp/md3                        # 隔离夹具，用于整窗截图
```
