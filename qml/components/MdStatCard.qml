import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 统计卡：标签 + 数值 + 说明 + 状态色条。 */
Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property string caption: ""
    property string status: "neutral"
    property string iconName: ""

    readonly property color statusColor: {
        switch (root.status) {
        case "primary": return Theme.colors.primary;
        case "success": return Theme.colors.success;
        case "warning": return Theme.colors.warning;
        case "error": return Theme.colors.error;
        default: return Theme.colors.outlineVariant;
        }
    }

    // 高度按内容算：写死 108 时「标签+数值+说明」实际要 86，说明文字会压到卡片下边框
    implicitHeight: Math.ceil(column.implicitHeight + Md3.space.lg * 2)
    implicitWidth: 220
    radius: Md3.shape.medium
    color: Theme.colors.surfaceContainerLow
    border.width: 1
    border.color: Theme.colors.outlineVariant

    // 状态色条：上下各让开圆角半径，否则直条会顶出卡片圆角（放大看得见方角）
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Md3.shape.medium - 2
        anchors.bottomMargin: Md3.shape.medium - 2
        width: 4
        radius: 2
        color: root.statusColor
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: Md3.space.lg
        anchors.leftMargin: Md3.space.xl
        spacing: Md3.space.xs

        Row {
            spacing: 6
            MdIcon {
                visible: root.iconName.length > 0
                name: root.iconName
                size: 16
                color: Theme.colors.onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            MdText {
                role: "labelMedium"
                tone: "variant"
                text: root.label
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
            }
        }

        MdText {
            role: "headlineMedium"
            text: root.value
            color: Theme.colors.onSurface
            elide: Text.ElideRight
            width: parent.width
        }

        MdText {
            role: "bodySmall"
            tone: "variant"
            text: root.caption
            elide: Text.ElideRight
            width: parent.width
            visible: root.caption.length > 0
        }
    }
}
