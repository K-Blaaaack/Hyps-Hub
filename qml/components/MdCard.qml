import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 卡片：filled / elevated / outlined 三种变体。
 *
 * 内容通过默认属性放进带内边距的 contentItem：
 *   MdCard {
 *       ColumnLayout { anchors.fill: parent; ... }
 *   }
 * 也可以不写 anchors，让卡片按内容自适应（implicitWidth/Height 取 childrenRect）。
 *
 * 规范：filled 用 surfaceContainerHighest，elevated 用 surfaceContainerLow + 阴影，
 * outlined 用 surface + 1dp outlineVariant；圆角默认 12dp（shape.medium）。
 */
Rectangle {
    id: card

    property string variant: "filled"        // filled | elevated | outlined
    property real cornerRadius: Md3.shape.medium
    property real padding: Md3.space.lg
    property bool interactive: false
    property bool selected: false
    property alias contentItem: body

    default property alias contentData: body.data

    signal clicked

    // 卡片尺寸取内容的 implicit 尺寸：单个子项（通常是 ColumnLayout）直接用它的，
    // 多个子项则按堆叠累加。不能用 childrenRect —— 子项 anchors.fill 时它恒为 0。
    readonly property int childCount: body.children.length
    readonly property Item innerContent: childCount === 1 ? body.children[0] : null

    implicitWidth: Math.ceil(card.contentWidth) + padding * 2
    implicitHeight: Math.ceil(card.contentHeight) + padding * 2

    readonly property real contentWidth: {
        if (card.childCount === 0) {
            return 0;
        }
        let w = 0;
        const kids = body.children;
        for (let i = 0; i < kids.length; ++i) {
            if (kids[i].visible === false) {
                continue;
            }
            w = Math.max(w, kids[i].implicitWidth);
        }
        return w;
    }

    readonly property real contentHeight: {
        if (card.childCount === 0) {
            return 0;
        }
        if (card.childCount === 1) {
            return body.children[0].implicitHeight;
        }
        let h = 0;
        let visible = 0;
        const kids = body.children;
        for (let i = 0; i < kids.length; ++i) {
            if (kids[i].visible === false) {
                continue;
            }
            h += kids[i].implicitHeight;
            visible += 1;
        }
        return h + Math.max(0, visible - 1) * Md3.space.sm;
    }
    radius: card.cornerRadius
    color: {
        switch (card.variant) {
        case "elevated":
            return Theme.colors.surfaceContainerLow;
        case "outlined":
            return Theme.colors.surface;
        default:
            return Theme.colors.surfaceContainerHighest;
        }
    }
    border.width: card.variant === "outlined" ? 1 : 0
    border.color: Theme.colors.outlineVariant

    // elevated 的柔和阴影：偏移半透明矩形（软件渲染下不用 shader 阴影）
    Rectangle {
        visible: card.variant === "elevated"
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        radius: card.cornerRadius
        color: Md3.alpha(Theme.colors.shadow, 0.12)
        z: -1
    }

    // 状态层（在内容之下，避免给文字染色）
    Rectangle {
        anchors.fill: parent
        radius: card.cornerRadius
        color: Theme.colors.primary
        opacity: !card.interactive
                 ? (card.selected ? Md3.state.hover : 0)
                 : (mouseArea.pressed ? Md3.state.pressed
                                      : (mouseArea.containsMouse ? Md3.state.hover
                                                                 : (card.selected ? Md3.state.hover : 0)))
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: card.padding
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: card.interactive
        hoverEnabled: card.interactive
        cursorShape: card.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.clicked()
    }
}
