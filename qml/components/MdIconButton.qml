import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 图标按钮：40dp 圆形，standard/filled/tonal/outlined 四种。 */
Item {
    id: root

    property string iconName: "settings"
    property string variant: "standard"
    property int size: 40
    property int iconSize: 24
    property bool danger: false
    property string tooltip: ""

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.tooltip.length > 0 ? root.tooltip : root.iconName
    Accessible.onPressAction: root.clicked()

    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()

    readonly property color contentColor: {
        if (!root.enabled) {
            return Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent);
        }
        if (root.danger) {
            return root.variant === "filled" ? Theme.colors.onError : Theme.colors.error;
        }
        switch (root.variant) {
        case "filled": return Theme.colors.onPrimary;
        case "tonal": return Theme.colors.onSecondaryContainer;
        case "outlined": return Theme.colors.onSurfaceVariant;
        default: return Theme.colors.onSurfaceVariant;
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: width / 2
        color: {
            if (root.variant === "filled") {
                return root.danger ? Theme.colors.error : Theme.colors.primary;
            }
            if (root.variant === "tonal") {
                return Theme.colors.secondaryContainer;
            }
            return "transparent";
        }
        border.width: root.variant === "outlined" ? 1 : 0
        border.color: root.danger ? Theme.colors.error : Theme.colors.outline

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.danger ? Theme.colors.error : Theme.colors.onSurface
            opacity: btnMouse.pressed ? Md3.state.pressed
                                      : (btnMouse.containsMouse ? Md3.state.hover : 0)
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2 }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.colors.primary
            opacity: root.activeFocus ? 1 : 0
        }
    }

    MdIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        color: root.contentColor
    }

    // 内联提示气泡：悬停 500ms 后出现，避免 Popup 在列表里抢焦点
    Rectangle {
        id: tip
        visible: opacity > 0
        opacity: (root.tooltip.length > 0 && tipTimer.triggered && btnMouse.containsMouse) ? 1 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: -height - 8
        width: tipLabel.implicitWidth + 16
        height: 26
        radius: Md3.shape.extraSmall
        color: Theme.colors.inverseSurface
        Behavior on opacity { NumberAnimation { duration: Md3.motion.short2 } }

        MdText {
            id: tipLabel
            anchors.centerIn: parent
            role: "bodySmall"
            text: root.tooltip
            color: Theme.colors.inverseOnSurface
        }
    }

    Timer {
        id: tipTimer
        property bool triggered: false
        interval: 500
        onTriggered: triggered = true
    }

    MouseArea {
        id: btnMouse
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse) {
                tipTimer.restart();
            } else {
                tipTimer.stop();
                tipTimer.triggered = false;
            }
        }
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.clicked();
        }
    }
}
