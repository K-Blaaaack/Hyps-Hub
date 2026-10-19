import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 任务列表项：索引 / 名称 / 状态 / 时间 / 退出码 */
Item {
    id: root

    property string indexText: "00"
    property string label: ""
    property string state: "running"
    property string stateText: ""
    property string detail: ""
    property string whenText: ""
    property string durationText: ""
    property int exitCode: 0
    property bool hasExitCode: false
    property bool selected: false
    property bool active: false

    signal clicked

    implicitHeight: 64
    activeFocusOnTab: true

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Accessible.name: root.label
    Accessible.description: root.stateText
    Accessible.role: Accessible.ListItem
    Accessible.focusable: true

    function stateKind() {
        if (root.state === "succeeded") return "state";
        if (root.state === "failed") return "danger";
        if (root.state === "canceled" || root.state === "timeout") return "warn";
        return "signal";
    }

    Rectangle {
        anchors.fill: parent
        color: root.selected ? Theme.colors.ink3
                             : (hover.containsMouse ? Theme.colors.ink3 : "transparent")
    }

    Rectangle {
        width: 2
        height: parent.height
        color: root.selected ? Theme.colors.signal : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Column {
            Layout.preferredWidth: 42
            spacing: 2

            MicroLabel {
                label: root.indexText
                color: root.selected ? Theme.colors.signal : Theme.colors.disabled
                microSize: 8
                tracking: 1.0
            }

            Rectangle {
                width: 18
                height: 1
                color: Theme.colors.line
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.active ? Theme.colors.paper : Theme.colors.paper2
                font.family: App.uiFontFamily
                font.pixelSize: 13
                font.weight: root.active ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }

            MicroLabel {
                Layout.fillWidth: true
                label: {
                    const parts = [];
                    if (root.detail.length > 0) {
                        parts.push(root.detail);
                    }
                    if (root.whenText.length > 0) {
                        parts.push(root.whenText);
                    }
                    if (root.durationText.length > 0) {
                        parts.push(root.durationText);
                    }
                    if (root.hasExitCode) {
                        parts.push("EXIT " + root.exitCode);
                    }
                    return parts.join(" · ");
                }
                color: root.hasExitCode && root.exitCode !== 0
                       ? Theme.colors.danger : Theme.colors.muted
                microSize: 9
                tracking: 0.6
                elide: Text.ElideRight
            }
        }

        ArkTag {
            text: root.stateText
            kind: root.stateKind()
            implicitHeight: 20
        }
    }

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: Theme.colors.signal
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.colors.rule
        opacity: 0.6
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.clicked();
        }
    }
}
