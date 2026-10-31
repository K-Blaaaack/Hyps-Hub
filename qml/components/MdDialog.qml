import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 basic dialog：标题（可带图标）+ 可滚动正文 + 右对齐操作区。
 *
 * 冻结 API：
 *   heading    标题（T.Dialog 的 title 是 FINAL，所以统一用 heading）
 *   iconName   标题左侧图标（MdIcon 名称）
 *   默认属性槽 正文，自动纵向排列；要撑满宽度请给子项 Layout.fillWidth: true
 *   actions    底部操作槽（RowLayout 数据，右对齐），用法：
 *              actions: [ MdButton { text: "取消"; variant: "text" },
 *                         MdButton { text: "确定"; variant: "filled" } ]
 *   open() / close()
 *
 * 规范：宽度 280–560（min(max(280, 内容宽 + 48), 560)），圆角 28
 * （shape.extraLarge），surfaceContainerHigh 底，24 内边距，标题 headlineSmall，
 * 正文 bodyMedium/onSurfaceVariant；正文超过约 60% 屏高时收进 Flickable 滚动。
 * 遮罩用 Modal 默认遮罩并染成 scrim 40%；进出为 medium2 淡入 + 缩放（OutCubic）。
 *
 * 注意：Popup 不支持 anchors，居中靠 x/y 计算，由组件自己完成。
 */
Popup {
    id: root

    property string heading: ""
    property string iconName: ""

    default property alias bodyData: bodyColumn.data
    property alias actions: actionsRow.data

    // 正文可视上限：约 60% 屏高，扣掉标题/操作区/内边距后剩下的部分。
    readonly property real maxBodyHeight: {
        const screenHeight = Overlay.overlay ? Overlay.overlay.height : 800;
        const chrome = root.padding * 2
                + (headingRow.visible ? headingRow.implicitHeight + Md3.space.lg : 0)
                + (actionsRow.visible ? actionsRow.implicitHeight + Md3.space.xl : 0);
        return Math.max(Md3.size.button * 2.4, screenHeight * 0.6 - chrome);
    }

    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: Md3.space.xl
    transformOrigin: Item.Center

    width: Math.min(Md3.size.dialogMaxWidth,
                    Math.max(Md3.size.dialogMinWidth, implicitWidth))
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    // Modal 默认遮罩（Overlay.modal），颜色取 MD3 scrim 40%
    Overlay.modal: Rectangle {
        color: Md3.alpha(Theme.colors.scrim, 0.4)
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Md3.motion.medium2
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.92
                to: 1
                duration: Md3.motion.medium2
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Md3.motion.short4
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.94
                duration: Md3.motion.short4
                easing.type: Easing.InCubic
            }
        }
    }

    background: Item {
        // 柔和阴影：软件渲染下不用 shader/MultiEffect，用偏移的半透明圆角矩形近似
        Rectangle {
            x: 0
            y: 3
            width: parent.width
            height: parent.height
            radius: Md3.shape.extraLarge
            color: Md3.alpha(Theme.colors.shadow, 0.22)
        }

        Rectangle {
            anchors.fill: parent
            radius: Md3.shape.extraLarge
            color: Theme.colors.surfaceContainerHigh
            Accessible.role: Accessible.Dialog
            Accessible.name: root.heading
        }
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 0

        RowLayout {
            id: headingRow
            visible: root.heading.length > 0 || root.iconName.length > 0
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.bottomMargin: Md3.space.lg
            spacing: Md3.space.md

            MdIcon {
                visible: root.iconName.length > 0
                name: root.iconName
                size: Md3.size.icon
                color: Theme.colors.secondary
                Layout.alignment: Qt.AlignTop
            }

            MdText {
                visible: root.heading.length > 0
                Layout.fillWidth: true
                role: "headlineSmall"
                text: root.heading
                wrapMode: Text.WordWrap
            }
        }

        Flickable {
            id: bodyFlick
            visible: bodyColumn.implicitHeight > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(bodyColumn.implicitHeight, root.maxBodyHeight)
            implicitWidth: bodyColumn.implicitWidth
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyColumn
                width: bodyFlick.width
                spacing: Md3.space.md
            }
        }

        RowLayout {
            id: actionsRow
            visible: children.length > 0
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: Md3.space.xl
            spacing: Md3.space.sm
        }
    }
}
