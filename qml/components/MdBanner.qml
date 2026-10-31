import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 提示条：info / success / warning / error，可带动作与关闭。 */
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property string text: ""
    property string status: "info"
    property string actionText: ""
    property bool closable: false

    signal actionClicked()
    signal closed()

    readonly property color containerColor: {
        switch (root.status) {
        case "success": return Theme.colors.successContainer;
        case "warning": return Theme.colors.warningContainer;
        case "error": return Theme.colors.errorContainer;
        default: return Theme.colors.secondaryContainer;
        }
    }
    readonly property color contentColor: {
        switch (root.status) {
        case "success": return Theme.colors.onSuccessContainer;
        case "warning": return Theme.colors.onWarningContainer;
        case "error": return Theme.colors.onErrorContainer;
        default: return Theme.colors.onSecondaryContainer;
        }
    }
    readonly property string statusIcon: {
        switch (root.status) {
        case "success": return "check-circle";
        case "warning": return "warning";
        case "error": return "error";
        default: return "info";
        }
    }

    implicitHeight: content.implicitHeight + Md3.space.lg * 2
    radius: Md3.shape.medium
    color: root.containerColor

    RowLayout {
        id: content
        anchors.fill: parent
        // 16 而不是 12：横幅常和卡片同屏，内边距不一致会让文字左轨错开 4px
        anchors.margins: Md3.space.lg
        spacing: Md3.space.sm

        MdIcon {
            name: root.statusIcon
            size: 20
            color: root.contentColor
            Layout.alignment: Qt.AlignTop
        }

        MdText {
            role: "bodyMedium"
            text: root.text
            color: root.contentColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignVCenter
        }

        MdButton {
            visible: root.actionText.length > 0
            text: root.actionText
            variant: "text"
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.actionClicked()
        }

        MdIconButton {
            visible: root.closable
            iconName: "close"
            size: 32
            iconSize: 18
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.closed()
        }
    }
}
