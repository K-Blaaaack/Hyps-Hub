import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 顶部状态栏：56px，贴边停靠真实状态，不做装饰性遥测 */
Rectangle {
    id: root

    property string pageTitle: ""
    property string pageEnglish: ""

    implicitHeight: 56
    color: Qt.rgba(Theme.colors.ink.r, Theme.colors.ink.g, Theme.colors.ink.b, 0.94)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.colors.rule
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        MicroLabel {
            label: "HYPS HUB //"
            color: Theme.colors.signal
            microSize: 9
            tracking: 1.6
        }

        MicroLabel {
            label: root.pageEnglish.length > 0 ? root.pageEnglish : root.pageTitle
            color: Theme.colors.paper2
            microSize: 9
            tracking: 1.4
        }

        Item { Layout.fillWidth: true }

        ArkTag {
            visible: App.runningAsRoot
            text: "ROOT"
            kind: "danger"
            implicitHeight: 20
        }

        ArkTag {
            visible: Runtime.updateAvailable
            text: "UPDATE " + Runtime.behindCount
            kind: "signal"
            implicitHeight: 20
        }

        MicroLabel {
            label: "ENV " + (EnvReport.hasReport
                             ? EnvReport.requiredPassed + "/" + EnvReport.requiredTotal
                             : "—")
            color: EnvReport.hasReport
                   ? (EnvReport.requiredFailed > 0 ? Theme.colors.danger : Theme.colors.state)
                   : Theme.colors.muted
            microSize: 9
            tracking: 1.2
        }

        ArkTag {
            text: Runtime.ready ? "COMPONENT" : "OFFLINE"
            kind: Runtime.ready ? "state" : "danger"
            implicitHeight: 20
        }

        MicroLabel {
            visible: Runtime.ready && Runtime.commitShort.length > 0
            label: Runtime.commitShort
            color: Theme.colors.muted
            microSize: 9
            tracking: 0.8
        }

        ArkButton {
            text: "检查环境"
            implicitHeight: 34
            font.pixelSize: 10
            enabled: Runtime.ready
            onClicked: Adapter.checkEnvironment()
        }
    }
}
