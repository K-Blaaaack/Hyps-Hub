import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* 键值信息行：左侧标签（次要色）+ 右侧值（等宽可选）+ 可选复制。 */
Item {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property string label: ""
    property string value: ""
    property bool mono: false
    property bool copyable: false

    signal copyRequested()

    implicitHeight: Math.max(32, valueText.implicitHeight + 8)

    RowLayout {
        anchors.fill: parent
        spacing: Md3.space.md

        MdText {
            role: "bodyMedium"
            tone: "variant"
            text: root.label
            Layout.preferredWidth: Math.min(200, Math.max(96, implicitWidth))
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }

        MdText {
            id: valueText
            role: "bodyMedium"
            mono: root.mono
            text: root.value.length > 0 ? root.value : "—"
            color: root.value.length > 0 ? Theme.colors.onSurface
                                         : Theme.colors.onSurfaceVariant
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            // 单行 + 中间省略：路径这类长值换行会被拆成两截（如 .../runt + ime/Hyps），
            // 比省略号更难读。
            wrapMode: Text.NoWrap
            elide: Text.ElideMiddle
        }

        MdIcon {
            visible: root.copyable && root.value.length > 0
            name: "copy"
            size: 18
            color: copyMouse.containsMouse ? Theme.colors.primary : Theme.colors.onSurfaceVariant
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                id: copyMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyRequested()
            }
        }
    }
}
