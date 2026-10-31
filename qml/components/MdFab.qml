import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 FAB：small 40 / regular 56 / large 96；带 text 时为 extended FAB。 */
Item {
    id: root

    property string iconName: "add"
    property string text: ""
    property string size: "regular"
    property string variant: "primary"

    signal clicked()

    readonly property real diameter: root.size === "small" ? 40
                                      : (root.size === "large" ? 96 : 56)
    readonly property bool extended: root.text.length > 0
    readonly property int iconPixels: root.size === "small" ? 20
                                      : (root.size === "large" ? 36 : 24)

    readonly property color containerColor: {
        switch (root.variant) {
        case "secondary": return Theme.colors.secondaryContainer;
        case "tertiary": return Theme.colors.tertiaryContainer;
        default: return Theme.colors.primaryContainer;
        }
    }
    readonly property color contentColor: {
        switch (root.variant) {
        case "secondary": return Theme.colors.onSecondaryContainer;
        case "tertiary": return Theme.colors.onTertiaryContainer;
        default: return Theme.colors.onPrimaryContainer;
        }
    }

    implicitWidth: extended ? fabRow.implicitWidth + 40 : diameter
    implicitHeight: extended ? 56 : diameter
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.extended ? root.text : root.iconName

    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: height / 2
        color: Md3.alpha(Theme.colors.shadow, 0.18)
        z: -1
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: height / 2
        color: root.enabled ? root.containerColor
                            : Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContainer)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.contentColor
            opacity: fabMouse.pressed ? Md3.state.pressed : (fabMouse.containsMouse ? Md3.state.hover : 0)
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2 }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.colors.primary
            opacity: root.activeFocus ? 1 : 0
        }
    }

    Row {
        id: fabRow
        anchors.centerIn: parent
        spacing: Md3.space.md

        MdIcon {
            name: root.iconName
            size: root.iconPixels
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }

        MdText {
            visible: root.extended
            role: "labelLarge"
            text: root.text
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: fabMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.clicked();
        }
    }
}
