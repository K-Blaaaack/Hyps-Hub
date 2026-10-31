import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 工具提示。
 *
 * 悬停 target 500ms 后出现，鼠标移出即隐藏；target 获得键盘焦点时也会显示。
 * 外观：inverseSurface 背景 + inverseOnSurface 文字 + labelMedium + shape.extraSmall，
 * 内边距 16（横）/ 8（纵），默认出现在 target 上方 4dp 处，越界时翻到下方并夹在窗口内。
 *
 * Qt 6.10 限制：Popup 不支持 anchors，只能用 x/y 定位（坐标相对于 popup 的 parent）。
 *
 * 用法：
 *   MdTooltip { text: "刷新"; target: refreshButton }        // 悬停自动显示
 *   MdTooltip { text: "…"; target: btn; shown: true }       // 调用方手动驱动（兼容）
 */
Popup {
    id: root

    property string text: ""
    property Item target: null
    // 兼容：调用方可以手动驱动显示；默认 false，靠悬停/聚焦自动显示
    property bool shown: false

    // 悬停多久出现（MD3 建议 500ms）
    readonly property int showDelay: Md3.motion.long2
    // 单行提示的最大宽度，超过后换行
    readonly property real tipMaxWidth: 240

    readonly property bool forceShown: root.shown && root.text.length > 0
    readonly property bool targetFocused: root.target !== null
                                          && root.target.activeFocus
                                          && root.text.length > 0

    // 悬停满 500ms 才置 true
    property bool hoverActive: false

    readonly property bool wantVisible: root.forceShown || root.targetFocused || root.hoverActive

    width: implicitWidth
    height: implicitHeight
    leftPadding: Md3.space.lg
    rightPadding: Md3.space.lg
    topPadding: Md3.space.sm
    bottomPadding: Md3.space.sm
    modal: false
    focus: false
    closePolicy: Popup.NoAutoClose
    visible: false

    onWantVisibleChanged: {
        if (root.wantVisible) {
            root.showNow();
        } else {
            root.hideNow();
        }
    }

    function showNow() {
        if (!root.text || root.text.length === 0) {
            return;
        }
        root.updatePosition();
        root.open();
    }

    function hideNow() {
        showTimer.stop();
        root.hoverActive = false;
        root.close();
    }

    function updatePosition() {
        if (!root.target || !root.parent) {
            return;
        }
        const pos = root.target.mapToItem(root.parent, 0, 0);
        const w = root.implicitWidth;
        const h = root.implicitHeight;
        const gap = Md3.space.xs;

        let tx = pos.x + (root.target.width - w) / 2;
        let ty = pos.y - h - gap;

        const bounds = root.sceneBounds();
        if (bounds.width > 0) {
            // 上方放不下就翻到 target 下方
            if (ty < gap) {
                ty = pos.y + root.target.height + gap;
            }
            tx = Math.max(gap, Math.min(tx, bounds.width - w - gap));
            ty = Math.max(gap, Math.min(ty, bounds.height - h - gap));
        }
        root.x = Math.round(tx);
        root.y = Math.round(ty);
    }

    function sceneBounds() {
        const result = { width: 0, height: 0 };
        const host = root.parent;
        if (!host) {
            return result;
        }
        const win = host.Window.window;
        if (win) {
            result.width = win.width;
            result.height = win.height;
        }
        return result;
    }

    // 追踪 target 的悬停：target 是别人的 Item，只能在它上面挂一个空 Item + HoverHandler
    // （HoverHandler 是被动处理器，不会抢 target 自己的鼠标事件）
    Item {
        id: probe
        parent: root.target
        width: root.target !== null ? root.target.width : 0
        height: root.target !== null ? root.target.height : 0
        visible: root.target !== null

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hoverHandler.hovered) {
                    if (root.text.length > 0) {
                        showTimer.restart();
                    }
                } else {
                    root.hideNow();
                }
            }
        }
    }

    Timer {
        id: showTimer
        interval: root.showDelay
        repeat: false
        onTriggered: root.hoverActive = root.text.length > 0
    }

    background: Rectangle {
        radius: Md3.shape.extraSmall
        color: Theme.colors.inverseSurface
    }

    contentItem: Item {
        implicitWidth: Math.min(measure.implicitWidth, root.tipMaxWidth)
        implicitHeight: label.implicitHeight

        // 不换行量一遍自然宽度，避免 Text 用自身 width 反推 implicitWidth 造成绑定循环
        Text {
            id: measure
            visible: false
            text: root.text
            font: label.font
        }

        MdText {
            id: label
            role: "labelMedium"
            tone: "inverse"
            text: root.text
            width: parent.implicitWidth
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
        }
    }
}
