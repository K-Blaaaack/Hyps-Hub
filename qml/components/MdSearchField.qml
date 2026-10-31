import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 搜索栏（胶囊）：48dp 高，左侧搜索图标，有内容时显示清空。 */
FocusScope {
    id: root

    property string placeholder: "搜索"
    property alias text: input.text
    property bool compact: false

    signal edited(string text)
    signal accepted()

    implicitHeight: root.compact ? 40 : 48
    implicitWidth: 240
    activeFocusOnTab: true

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.colors.surfaceContainerHigh
        border.width: input.activeFocus ? 2 : 0
        border.color: Theme.colors.primary
    }

    MdIcon {
        id: leadingIcon
        name: "search"
        size: 20
        color: Theme.colors.onSurfaceVariant
        x: 14
        anchors.verticalCenter: parent.verticalCenter
    }

    MdIcon {
        visible: input.text.length > 0
        name: "close"
        size: 18
        color: Theme.colors.onSurfaceVariant
        x: root.width - width - 14
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                input.text = "";
                root.edited("");
            }
        }
    }

    TextInput {
        id: input
        anchors.left: leadingIcon.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: input.text.length > 0 ? 38 : 14
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.colors.onSurface
        selectionColor: Theme.colors.primary
        selectedTextColor: Theme.colors.onPrimary
        font.family: App.uiFontFamily
        font.pixelSize: Md3.type.bodyLarge.size
        selectByMouse: true
        clip: true
        Accessible.name: root.placeholder

        onTextEdited: root.edited(text)
        onAccepted: root.accepted()

        MdText {
            visible: input.text.length === 0
            text: root.placeholder
            role: "bodyLarge"
            color: Md3.alpha(Theme.colors.onSurfaceVariant, 0.7)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: input.forceActiveFocus()
    }
}
