import QtQuick
import HypsHub 1.0

/* 方角开关：44px 命中区，信号色表示启用，不使用圆角/阴影 */
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 44
    activeFocusOnTab: true

    Rectangle {
        anchors.centerIn: parent
        width: 40
        height: 20
        color: "transparent"
        border.width: 1
        border.color: root.checked ? Theme.colors.signal
                    : (mouse.containsMouse ? Theme.colors.lineHover : Theme.colors.line)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? 22 : 4
        width: 14
        height: 14
        color: root.checked ? Theme.colors.signal : Theme.colors.disabled

        Behavior on x {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        border.width: 2
        border.color: Theme.colors.signal
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }

    Keys.onSpacePressed: root.toggled(!root.checked)
}
