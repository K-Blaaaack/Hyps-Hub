import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 首页状态卡：微标签 + 大号数值 + 说明 + 状态徽标 */
ChamferedPanel {
    id: root

    property string english: ""
    property string label: ""
    property string value: ""
    property string sub: ""
    property string statusText: ""
    property string statusKind: "neutral"

    implicitHeight: 122
    contentMargin: 16
    cut: 9

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MicroLabel {
                Layout.fillWidth: true
                label: root.english
                color: Theme.colors.signal
                microSize: 9
                tracking: 1.6
            }

            ArkTag {
                visible: root.statusText.length > 0
                text: root.statusText
                kind: root.statusKind
                implicitHeight: 20
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.value
            color: Theme.colors.paper
            font.family: App.displayFontFamily
            font.pixelSize: 22
            font.weight: Font.DemiBold
            font.letterSpacing: -0.3
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.colors.paper2
            font.family: App.uiFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            Layout.fillWidth: true
            text: root.sub
            color: Theme.colors.muted
            font.family: App.monoFontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
