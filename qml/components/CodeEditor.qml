import QtQuick
import QtQuick.Controls
import HypsHub 1.0

/*
 * 大文本编辑器：Flickable + TextEdit，支持横向/纵向滚动条。
 *
 * 固定高度的 TextArea 无法把内容尺寸交给外层，长配置会被裁切且不可滚动。
 * 这里显式用 Flickable 承载 TextEdit，滚动条常显，滚轮、拖动与选择都可用。
 */
Item {
    id: root

    property alias text: edit.text
    property alias readOnly: edit.readOnly
    property string placeholderText: ""
    property int editorHeight: 220
    readonly property bool editing: edit.activeFocus

    implicitHeight: editorHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.codeBg
        border.width: 1
        border.color: edit.activeFocus ? Theme.colors.signal : Theme.colors.line

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 1
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: edit.width
            contentHeight: edit.height

            ScrollBar.vertical: ScrollBar {
                id: vbar
                policy: ScrollBar.AlwaysOn
                width: 8
                contentItem: Rectangle {
                    implicitWidth: 6
                    implicitHeight: 36
                    radius: 0
                    color: Theme.colors.scrollbar
                    opacity: vbar.pressed ? 1.0 : 0.75
                }
                background: Rectangle {
                    implicitWidth: 8
                    color: Theme.colors.ink3
                }
            }

            ScrollBar.horizontal: ScrollBar {
                id: hbar
                policy: ScrollBar.AlwaysOn
                height: 8
                contentItem: Rectangle {
                    implicitWidth: 36
                    implicitHeight: 6
                    radius: 0
                    color: Theme.colors.scrollbar
                    opacity: hbar.pressed ? 1.0 : 0.75
                }
                background: Rectangle {
                    implicitHeight: 8
                    color: Theme.colors.ink3
                }
            }

            TextEdit {
                id: edit
                width: Math.max(flick.width, edit.contentWidth + leftPadding + rightPadding)
                height: Math.max(flick.height, edit.contentHeight + topPadding + bottomPadding)
                color: Theme.colors.paper2
                selectionColor: Theme.colors.signal
                selectedTextColor: Theme.colors.onSignal
                font.family: App.monoFontFamily
                font.pixelSize: 12
                selectByMouse: true
                wrapMode: TextEdit.NoWrap
                leftPadding: 10
                rightPadding: 10
                topPadding: 8
                bottomPadding: 8
            }

            Text {
                x: 12
                y: 10
                visible: edit.text.length === 0 && !edit.activeFocus
                text: root.placeholderText
                color: Theme.colors.disabled
                font.family: App.uiFontFamily
                font.pixelSize: 11
            }
        }
    }
}
