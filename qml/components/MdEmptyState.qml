import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* MD3 空态：图标 + 标题 + 说明 + 可选动作。 */
Item {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property string iconName: "folder"
    // 圆底色：默认 surfaceContainerHigh；放进同色容器（弹窗）时要换一档，否则圆底看不见
    property color containerColor: Theme.colors.surfaceContainerHigh
    property string title: ""
    property string description: ""
    property string actionText: ""

    signal actionClicked()

    implicitHeight: column.implicitHeight + 32

    Column {
        id: column
        anchors.centerIn: parent
        width: Math.min(root.width > 0 ? root.width - 48 : 320, 420)
        spacing: Md3.space.md

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96
            height: 96
            radius: 48
            color: root.containerColor

            MdIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: 44
                color: Theme.colors.onSurfaceVariant
            }
        }

        MdText {
            width: parent.width
            role: "titleMedium"
            text: root.title
            color: Theme.colors.onSurface
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        MdText {
            width: parent.width
            role: "bodyMedium"
            tone: "variant"
            text: root.description
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: root.description.length > 0
        }

        MdButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionText.length > 0
            text: root.actionText
            variant: "tonal"
            onClicked: root.actionClicked()
        }
    }
}
