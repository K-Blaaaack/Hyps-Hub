import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 菜单容器：Popup + Column，x/y 定位（Popup 不支持 anchors）。 */
Popup {
    id: root

    default property alias contentData: column.data

    property int minWidth: 160
    property int maxHeight: 320

    padding: 4
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.max(root.minWidth, column.implicitWidth + root.padding * 2)
    height: Math.min(root.maxHeight, column.implicitHeight + root.padding * 2)
    transformOrigin: Item.Top

    background: Rectangle {
        radius: Md3.shape.extraSmall
        color: Theme.colors.surfaceContainer
        border.width: 1
        border.color: Theme.colors.outlineVariant

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            radius: parent.radius
            color: Md3.alpha(Theme.colors.shadow, 0.12)
            z: -1
        }
    }

    contentItem: Flickable {
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: column.implicitHeight > root.height - root.padding * 2

        Column {
            id: column
            width: parent.width
        }

        ScrollBar.vertical: MdScrollBar { }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Md3.motion.short3 }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Md3.motion.short4; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Md3.motion.short2 }
    }
}
