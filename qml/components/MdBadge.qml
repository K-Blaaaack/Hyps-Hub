import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 徽标：8dp 圆点，或最小 16dp 的计数胶囊。 */
Item {
    id: root

    property string text: ""
    property bool dot: false
    property string status: "error"

    readonly property color badgeColor: {
        switch (root.status) {
        case "primary": return Theme.colors.primary;
        case "success": return Theme.colors.success;
        case "warning": return Theme.colors.warning;
        case "neutral": return Theme.colors.outline;
        default: return Theme.colors.error;
        }
    }
    readonly property color badgeTextColor: {
        switch (root.status) {
        case "primary": return Theme.colors.onPrimary;
        case "success": return Theme.colors.onSuccess;
        case "warning": return Theme.colors.onWarning;
        case "neutral": return Theme.colors.onSurfaceVariant;
        default: return Theme.colors.onError;
        }
    }

    implicitWidth: root.dot ? 8 : Math.max(16, label.implicitWidth + 8)
    implicitHeight: root.dot ? 8 : 16

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.badgeColor
    }

    MdText {
        id: label
        visible: !root.dot
        anchors.centerIn: parent
        role: "labelSmall"
        text: root.text
        color: root.badgeTextColor
    }
}
