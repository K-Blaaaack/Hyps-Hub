import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* 任务列表项：左侧状态条 + 标签 + 状态/时长 + 错误摘要。 */
Item {
    id: root
    Layout.fillWidth: true

    property string taskId: ""
    property string label: ""
    property string stateText: ""
    property string kind: ""
    property string durationText: ""
    property string errorSummary: ""
    property bool active: false
    property bool selected: false

    signal clicked()

    implicitHeight: root.errorSummary.length > 0 ? 80 : 64
    implicitWidth: 280

    function stateColor() {
        const state = String(root.stateText);
        if (root.active) {
            return Theme.colors.primary;
        }
        if (/失败|错误|超时|failed|error|timeout/i.test(state)) {
            return Theme.colors.error;
        }
        if (/成功|完成|succeeded|finished|done/i.test(state)) {
            return Theme.colors.success;
        }
        if (/取消|cancel/i.test(state)) {
            return Theme.colors.outline;
        }
        return Theme.colors.outline;
    }

    Rectangle {
        anchors.fill: parent
        radius: Md3.shape.small
        color: root.selected ? Theme.colors.secondaryContainer : "transparent"

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.colors.onSurface
            opacity: rowMouse.containsMouse && !root.selected ? Md3.state.hover : 0
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2 }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        width: 4
        radius: 2
        color: root.stateColor()
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        MdText {
            width: parent.width
            role: "bodyLarge"
            text: root.label
            color: root.selected ? Theme.colors.onSecondaryContainer : Theme.colors.onSurface
            elide: Text.ElideRight
        }

        Row {
            spacing: 8

            MdText {
                role: "bodySmall"
                text: root.stateText
                color: root.stateColor()
            }

            MdText {
                visible: root.durationText.length > 0
                role: "bodySmall"
                tone: "variant"
                text: root.durationText
            }

            MdText {
                visible: root.kind.length > 0
                role: "bodySmall"
                tone: "variant"
                text: root.kind
            }
        }

        MdText {
            visible: root.errorSummary.length > 0
            width: parent.width
            role: "bodySmall"
            color: Theme.colors.error
            text: root.errorSummary
            elide: Text.ElideRight
        }
    }

    MdProgressLinear {
        visible: root.active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        thickness: 2
        value: -1
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
