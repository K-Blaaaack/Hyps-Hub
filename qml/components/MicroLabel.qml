import QtQuick
import HypsHub 1.0

Text {
    id: root

    property string label: ""
    property bool mono: true
    property real microSize: 10
    property real tracking: 1.5

    text: label
    color: Theme.colors.muted
    font.family: mono ? App.monoFontFamily : App.uiFontFamily
    font.pixelSize: microSize
    font.letterSpacing: tracking
    font.capitalization: Font.AllUppercase
    verticalAlignment: Text.AlignVCenter
}
