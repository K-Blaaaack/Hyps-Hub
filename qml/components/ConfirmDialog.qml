import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/* 危险/重要操作确认：明确说明后果 */
Popup {
    id: popup

    property string title: "请确认"
    property string message: ""
    property string confirmText: "确认"
    property string cancelText: "取消"
    property bool danger: false

    signal accepted

    modal: true
    focus: true
    padding: 24
    closePolicy: Popup.CloseOnEscape
    width: Math.min(460, Overlay.overlay ? Overlay.overlay.width - 80 : 460)
    anchors.centerIn: Overlay.overlay

    background: ChamferedPanel {
        cut: 10
        contentMargin: 0
        accentColor: popup.danger ? Theme.colors.danger : Theme.colors.signal
    }

    contentItem: ColumnLayout {
        spacing: 14

        MicroLabel {
            label: popup.danger ? "IRREVERSIBLE / CONFIRM" : "CONFIRM"
            color: popup.danger ? Theme.colors.danger : Theme.colors.signal
            microSize: 9
            tracking: 1.6
        }

        Text {
            Layout.fillWidth: true
            text: popup.title
            color: Theme.colors.paper
            font.family: App.uiFontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Text {
            Layout.fillWidth: true
            text: popup.message
            color: Theme.colors.paper2
            font.family: App.uiFontFamily
            font.pixelSize: 12
            lineHeight: 1.35
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10

            Item { Layout.fillWidth: true }

            ArkButton {
                text: popup.cancelText
                implicitHeight: 40
                ghost: true
                onClicked: popup.close()
            }

            ArkButton {
                text: popup.confirmText
                implicitHeight: 40
                primary: true
                danger: popup.danger
                onClicked: {
                    popup.close();
                    popup.accepted();
                }
            }
        }
    }
}
