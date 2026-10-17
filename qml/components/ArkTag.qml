import QtQuick
import QtQuick.Shapes
import HypsHub 1.0

/* 状态徽标 / 标签 Chip：左上 4px 单切，零圆角 */
Item {
    id: root

    property string text: ""
    property string kind: "neutral" // neutral | signal | state | warn | danger

    implicitWidth: label.implicitWidth + 18
    implicitHeight: 24

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            strokeWidth: root.kind === "warn" || root.kind === "danger" ? 1 : 0
            strokeColor: root.kind === "warn" ? Theme.colors.warn
                       : (root.kind === "danger" ? Theme.colors.danger : "transparent")
            fillColor: root.kind === "state" ? Theme.colors.state
                     : (root.kind === "signal" ? Theme.colors.signalDim
                        : (root.kind === "neutral" ? Theme.colors.ink3 : "transparent"))
            joinStyle: ShapePath.MiterJoin

            startX: 4
            startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 4 }
            PathLine { x: 4; y: 0 }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.kind === "state" ? Theme.colors.onState
             : (root.kind === "signal" ? Theme.colors.signal
                : (root.kind === "warn" ? Theme.colors.warn
                   : (root.kind === "danger" ? Theme.colors.danger
                      : Theme.colors.paper2)))
        font.family: App.monoFontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1.4
        font.capitalization: Font.AllUppercase
    }
}
