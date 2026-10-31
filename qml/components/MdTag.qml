import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 状态胶囊：高 24dp、圆角 8dp（shape.small）、labelSmall。
 * status 决定容器/文字配色；outlined 时改为透明底 + 1dp 同色描边。
 */
Item {
    id: root

    property string text: ""
    property string status: "neutral"
    property string iconName: ""
    property bool outlined: false

    implicitHeight: 24
    implicitWidth: row.implicitWidth + (root.iconName.length > 0 ? 22 : 16)

    function containerColor() {
        switch (root.status) {
        case "primary": return Theme.colors.primaryContainer;
        case "success": return Theme.colors.successContainer;
        case "warning": return Theme.colors.warningContainer;
        case "error": return Theme.colors.errorContainer;
        case "tertiary": return Theme.colors.tertiaryContainer;
        default: return Theme.colors.surfaceContainerHigh;
        }
    }

    function contentColor() {
        switch (root.status) {
        case "primary": return Theme.colors.onPrimaryContainer;
        case "success": return Theme.colors.onSuccessContainer;
        case "warning": return Theme.colors.onWarningContainer;
        case "error": return Theme.colors.onErrorContainer;
        case "tertiary": return Theme.colors.onTertiaryContainer;
        default: return Theme.colors.onSurfaceVariant;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Md3.shape.small
        color: root.outlined ? "transparent" : root.containerColor()
        border.width: root.outlined ? 1 : 0
        border.color: root.outlined ? root.contentColor() : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        MdIcon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: 14
            color: root.contentColor()
            anchors.verticalCenter: parent.verticalCenter
        }

        MdText {
            role: "labelSmall"
            text: root.text
            color: root.contentColor()
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }
}
