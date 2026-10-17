import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 区块标题：NN / 英文微标签 / 中文标题 / 45° 警戒线标尺 */
Item {
    id: root

    property string index: "01"
    property string title: ""
    property string english: ""

    implicitHeight: 26

    RowLayout {
        anchors.fill: parent
        spacing: 12

        MicroLabel {
            label: root.index + " /"
            color: Theme.colors.muted
            microSize: 10
            tracking: 1.2
        }

        MicroLabel {
            label: root.english
            color: Theme.colors.signal
            microSize: 10
            tracking: 1.8
        }

        Text {
            text: root.title
            color: Theme.colors.paper
            font.family: App.uiFontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }

        StripeRuler {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
