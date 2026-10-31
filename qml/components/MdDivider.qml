import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* MD3 分割线：1dp outlineVariant，可缩进、可竖排。 */
Item {
    id: root
    Layout.fillWidth: !root.vertical
    Layout.fillHeight: root.vertical

    property bool inset: false
    property bool vertical: false

    implicitWidth: root.vertical ? 1 : 200
    implicitHeight: root.vertical ? 200 : 1

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: root.vertical ? 0 : (root.inset ? Md3.space.lg : 0)
        anchors.rightMargin: root.vertical ? 0 : (root.inset ? Md3.space.lg : 0)
        anchors.topMargin: root.vertical ? (root.inset ? Md3.space.lg : 0) : 0
        anchors.bottomMargin: root.vertical ? (root.inset ? Md3.space.lg : 0) : 0
        color: Theme.colors.outlineVariant
    }
}
