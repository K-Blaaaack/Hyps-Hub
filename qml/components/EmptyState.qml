import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 空状态：不伪造内容，只说明发生了什么与下一步 */
Item {
    id: root

    property string title: "暂无内容"
    property string description: ""
    property string actionText: ""
    property string indexText: "00"

    signal actionTriggered

    implicitHeight: 180

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 460)
        spacing: 10

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            MicroLabel {
                label: root.indexText
                color: Theme.colors.signal
                microSize: 10
                tracking: 1.6
            }

            Rectangle {
                width: 48
                height: 1
                color: Theme.colors.line
            }

            MicroLabel {
                label: "NO DATA"
                color: Theme.colors.muted
                microSize: 9
                tracking: 1.4
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.colors.paper2
            font.family: App.uiFontFamily
            font.pixelSize: 15
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            visible: text.length > 0
            color: Theme.colors.muted
            font.family: App.uiFontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        ArkButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            text: root.actionText
            visible: root.actionText.length > 0
            primary: true
            onClicked: root.actionTriggered()
        }
    }
}
