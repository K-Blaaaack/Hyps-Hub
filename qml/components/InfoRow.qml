import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 标签 / 值行，等宽显示路径与数值 */
RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property bool mono: true
    property bool wrap: false
    property color valueColor: Theme.colors.paper2

    spacing: 12

    MicroLabel {
        Layout.preferredWidth: 96
        Layout.alignment: Qt.AlignTop
        label: root.label
        color: Theme.colors.muted
        microSize: 9
        tracking: 1.2
    }

    Text {
        Layout.fillWidth: true
        text: root.value
        color: root.valueColor
        font.family: root.mono ? App.monoFontFamily : App.uiFontFamily
        font.pixelSize: 12
        wrapMode: root.wrap ? Text.WrapAnywhere : Text.NoWrap
        elide: root.wrap ? Text.ElideNone : Text.ElideMiddle
    }
}
