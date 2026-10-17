import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 编辑式页头：NN 索引 + 大型 CJK 标题 + 双语微标签 */
Item {
    id: root

    property string index: "01"
    property string title: ""
    property string english: ""
    property string subtitle: ""
    default property alias actions: actionsRow.data

    implicitHeight: 104

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 5

        MicroLabel {
            label: root.index + " / " + root.english
            color: Theme.colors.signal
            microSize: 10
            tracking: 1.8
        }

        Text {
            text: root.title
            color: Theme.colors.paper
            font.family: App.uiFontFamily
            font.pixelSize: 36
            font.weight: Font.Bold
            font.letterSpacing: -0.4
            lineHeight: 1.0
        }

        MicroLabel {
            visible: root.subtitle.length > 0
            label: root.subtitle
            color: Theme.colors.muted
            microSize: 10
            tracking: 1.4
        }
    }

    Row {
        id: actionsRow
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.colors.rule
    }
}
