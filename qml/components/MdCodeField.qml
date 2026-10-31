import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* 多行等宽输入区：outline 容器 + 内部 Flickable（长文本可滚动）。 */
FocusScope {
    id: root
    Layout.fillWidth: true

    property alias text: edit.text
    property string label: ""
    property string placeholderText: ""
    property bool readOnly: false
    property bool wrap: false
    property int minHeight: 160
    readonly property bool editing: edit.activeFocus

    implicitHeight: Math.max(root.minHeight, 120)
    implicitWidth: 320
    activeFocusOnTab: !root.readOnly

    Rectangle {
        id: container
        anchors.fill: parent
        radius: Md3.shape.medium
        color: Theme.colors.codeSurface
        border.width: edit.activeFocus ? 2 : 1
        border.color: edit.activeFocus ? Theme.colors.primary : Theme.colors.outlineVariant

        MouseArea {
            anchors.fill: parent
            onClicked: if (!root.readOnly) edit.forceActiveFocus()
        }
    }

    MdText {
        visible: root.label.length > 0
        text: root.label
        role: "labelSmall"
        color: edit.activeFocus ? Theme.colors.primary : Theme.colors.onSurfaceVariant
        x: 14
        y: -height - 2
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: root.wrap ? flick.width : edit.contentWidth
        contentHeight: edit.height
        ScrollBar.vertical: MdScrollBar { }
        ScrollBar.horizontal: MdScrollBar { policy: ScrollBar.AsNeeded }

        TextEdit {
            id: edit
            width: root.wrap ? flick.width : 100000
            height: Math.max(flick.height, contentHeight)
            color: Theme.colors.onSurface
            selectionColor: Theme.colors.primary
            selectedTextColor: Theme.colors.onPrimary
            font.family: App.monoFontFamily
            font.pixelSize: Md3.type.bodyMedium.size
            wrapMode: root.wrap ? TextEdit.WrapAnywhere : TextEdit.NoWrap
            readOnly: root.readOnly
            selectByMouse: true
            persistentSelection: true
            textFormat: TextEdit.PlainText
            Accessible.name: root.label.length > 0 ? root.label : root.placeholderText

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Tab && !event.modifiers) {
                    edit.insert(edit.cursorPosition, "  ");
                    event.accepted = true;
                }
            }

            MdText {
                visible: edit.text.length === 0 && root.placeholderText.length > 0
                text: root.placeholderText
                role: "bodyMedium"
                color: Md3.alpha(Theme.colors.onSurfaceVariant, 0.7)
                x: 0
                y: 0
            }
        }
    }
}
