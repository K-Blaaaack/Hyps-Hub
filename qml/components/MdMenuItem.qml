import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 菜单项：48dp 高，左图标 + 文字，destructive 用 error 色。 */
Item {
    id: root

    property string text: ""
    property string iconName: ""
    property bool destructive: false

    signal triggered()

    implicitHeight: 48
    implicitWidth: Math.max(160, content.implicitWidth + 32)
    activeFocusOnTab: true

    Accessible.role: Accessible.MenuItem
    Accessible.name: root.text

    function dismiss() {
        let node = root.parent;
        while (node) {
            if (typeof node.close === "function" && node.hasOwnProperty("modal")) {
                node.close();
                return;
            }
            node = node.parent;
        }
    }

    Keys.onReturnPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    function activate() {
        if (!root.enabled) {
            return;
        }
        root.triggered();
        root.dismiss();
    }

    Rectangle {
        anchors.fill: parent
        color: root.destructive ? Theme.colors.error : Theme.colors.onSurface
        opacity: itemMouse.pressed ? Md3.state.pressed
                                   : (itemMouse.containsMouse ? Md3.state.hover : 0)
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2 }
        }
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 12

        MdIcon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: 20
            color: root.destructive ? Theme.colors.error : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        MdText {
            role: "bodyLarge"
            text: root.text
            color: root.destructive ? Theme.colors.error : Theme.colors.onSurface
            opacity: root.enabled ? 1 : Md3.state.disabledContent
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}
