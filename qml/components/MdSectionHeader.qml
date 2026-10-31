import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 区块标题：titleSmall + 可选图标 + 右侧动作槽。 */
Item {
    id: root
    Layout.fillWidth: true
    implicitWidth: 240

    property string title: ""
    property string caption: ""
    property string iconName: ""

    default property alias trailing: trailingRow.data

    implicitHeight: 40

    RowLayout {
        anchors.fill: parent
        spacing: Md3.space.sm

        MdIcon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: 18
            color: Theme.colors.primary
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            MdText {
                role: "titleSmall"
                text: root.title
                color: Theme.colors.onSurface
                elide: Text.ElideRight
            }
            MdText {
                visible: root.caption.length > 0
                role: "labelSmall"
                text: root.caption
                tone: "variant"
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: trailingRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Md3.space.sm
        }
    }
}
