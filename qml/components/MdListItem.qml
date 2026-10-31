import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* MD3 列表项：单行 56dp / 双行 72dp。 */
Item {
    id: root
    Layout.fillWidth: true

    property string headline: ""
    property string supporting: ""
    property string leadingIcon: ""
    property string trailingText: ""
    property string trailingIcon: ""
    property string status: "neutral"
    property bool selected: false
    property bool interactive: false

    signal clicked()

    readonly property bool twoLine: root.supporting.length > 0
    implicitHeight: root.twoLine ? Md3.size.listItemTwoLine : Md3.size.listItem
    implicitWidth: 280

    Accessible.role: Accessible.ListItem
    Accessible.name: root.headline
    Accessible.description: root.supporting

    function statusColor() {
        switch (root.status) {
        case "primary": return Theme.colors.primary;
        case "success": return Theme.colors.success;
        case "warning": return Theme.colors.warning;
        case "error": return Theme.colors.error;
        default: return Theme.colors.outline;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.selected ? Theme.colors.secondaryContainer : "transparent"

        Rectangle {
            anchors.fill: parent
            color: root.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
            opacity: itemMouse.pressed && root.interactive ? Md3.state.pressed
                     : (itemMouse.containsMouse && root.interactive ? Md3.state.hover : 0)
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2 }
            }
        }
    }

    MdIcon {
        id: leading
        visible: root.leadingIcon.length > 0
        name: root.leadingIcon
        size: 24
        color: root.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurfaceVariant
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.left: root.leadingIcon.length > 0 ? leading.right : parent.left
        anchors.leftMargin: root.leadingIcon.length > 0 ? 16 : 16
        anchors.right: trailingArea.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        MdText {
            width: parent.width
            role: "bodyLarge"
            text: root.headline
            color: root.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
            elide: Text.ElideRight
        }

        MdText {
            visible: root.twoLine
            width: parent.width
            role: "bodySmall"
            tone: root.selected ? "default" : "variant"
            color: root.selected ? Theme.colors.onSecondaryContainer
                                 : Theme.colors.onSurfaceVariant
            text: root.supporting
            elide: Text.ElideRight
        }
    }

    Row {
        id: trailingArea
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        MdText {
            visible: root.trailingText.length > 0
            role: "labelMedium"
            text: root.trailingText
            color: root.selected ? Theme.colors.onSecondaryContainer
                                 : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        MdIcon {
            visible: root.trailingIcon.length > 0
            name: root.trailingIcon
            size: 24
            color: root.selected ? Theme.colors.onSecondaryContainer
                                 : Theme.colors.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            visible: root.status !== "neutral"
            width: 8
            height: 8
            radius: 4
            color: root.statusColor()
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.interactive) root.clicked()
    }
}
