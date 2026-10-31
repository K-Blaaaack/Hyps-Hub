import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 芯片：assist / filter / input / suggestion 四种，高 32dp、圆角 8dp。 */
Item {
    id: root

    property string text: ""
    property string variant: "assist"
    property bool selected: false
    property string iconName: ""
    property string status: "neutral"
    property bool removable: false

    signal clicked()
    signal removed()

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 16 + (root.removable ? 20 : 0)

    readonly property bool outlined: {
        if (root.variant === "filter") {
            return !root.selected;
        }
        if (root.variant === "input") {
            return false;
        }
        return true;
    }

    readonly property color containerColor: {
        if (root.variant === "input") {
            return Theme.colors.surfaceContainerHigh;
        }
        if (root.variant === "filter" && root.selected) {
            return Theme.colors.secondaryContainer;
        }
        return "transparent";
    }

    readonly property color contentColor: {
        if (root.variant === "filter" && root.selected) {
            return Theme.colors.onSecondaryContainer;
        }
        switch (root.status) {
        case "primary": return Theme.colors.primary;
        case "success": return Theme.colors.success;
        case "warning": return Theme.colors.warning;
        case "error": return Theme.colors.error;
        default: return Theme.colors.onSurface;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Md3.shape.small
        color: root.containerColor
        border.width: root.outlined ? 1 : 0
        border.color: root.selected ? "transparent" : Theme.colors.outlineVariant

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.contentColor
            opacity: chipMouse.pressed ? Md3.state.pressed
                                       : (chipMouse.containsMouse ? Md3.state.hover
                                                                  : (root.selected && root.variant !== "filter"
                                                                     ? Md3.state.hover : 0))
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2 }
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MdIcon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: 18
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }

        MdText {
            role: "labelLarge"
            text: root.text
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }

        MdIcon {
            visible: root.removable
            name: "close"
            size: 16
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removed()
            }
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
