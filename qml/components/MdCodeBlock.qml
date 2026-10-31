import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* 只读代码块：codeSurface 底 + 右上角复制。 */
Rectangle {
    id: root
    Layout.fillWidth: true

    property string text: ""
    property int maxHeight: 240
    property bool wrap: false

    implicitHeight: Math.min(root.maxHeight, contentText.implicitHeight + 24)
    implicitWidth: 320
    radius: Md3.shape.small
    color: Theme.colors.codeSurface
    border.width: 1
    border.color: Theme.colors.outlineVariant
    clip: true

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        contentWidth: contentText.width
        contentHeight: contentText.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MdScrollBar { }

        Text {
            id: contentText
            width: root.wrap ? Math.max(parent.width, 1) : Math.max(implicitWidth, 1)
            color: Theme.colors.onSurface
            font.family: App.monoFontFamily
            font.pixelSize: Md3.type.bodySmall.size
            text: root.text
            textFormat: Text.PlainText
            wrapMode: root.wrap ? Text.WrapAnywhere : Text.NoWrap
        }
    }

    MdIconButton {
        iconName: "copy"
        size: 32
        iconSize: 16
        tooltip: "复制"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        onClicked: AppControl.copyToClipboard(root.text)
    }
}
