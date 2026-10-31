import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 排版组件：把 15 个 typescale 角色收成一个组件，避免各页面散落 pixelSize。
 *
 * 用法：
 *   MdText { role: "headlineSmall"; text: "游戏" }
 *   MdText { role: "bodySmall"; tone: "variant"; text: "…"; wrapMode: Text.WordWrap }
 */
Text {
    id: root

    property string role: "bodyMedium"
    property bool mono: false
    // tone: default | variant | primary | error | success | warning | inverse
    property string tone: "default"
    property bool strong: false

    readonly property var style: Md3.type[role] !== undefined ? Md3.type[role] : Md3.type.bodyMedium

    function toneColor() {
        switch (root.tone) {
        case "variant":
            return Theme.colors.onSurfaceVariant;
        case "primary":
            return Theme.colors.primary;
        case "secondary":
            return Theme.colors.secondary;
        case "error":
            return Theme.colors.error;
        case "success":
            return Theme.colors.success;
        case "warning":
            return Theme.colors.warning;
        case "inverse":
            return Theme.colors.inverseOnSurface;
        case "onPrimary":
            return Theme.colors.onPrimary;
        default:
            return Theme.colors.onSurface;
        }
    }

    color: root.toneColor()
    font.family: root.mono ? App.monoFontFamily : App.uiFontFamily
    font.pixelSize: root.style.size
    font.weight: root.strong ? Font.DemiBold : root.style.weight
    font.letterSpacing: root.style.tracking
    // MD3 的行高是绝对像素（如 headlineMedium = 36），不是倍率。
    // 用 ProportionalHeight 会再乘一遍字体自然行高，正文块比规范高 15% 左右，
    // 所有「按文字高度」排的间距都会跟着虚胖。
    lineHeight: root.style.lineHeight
    lineHeightMode: Text.FixedHeight
    renderType: Text.NativeRendering
    wrapMode: Text.NoWrap
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation { duration: Md3.motion.short2 }
    }
}
