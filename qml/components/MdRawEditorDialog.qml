import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* 原始配置编辑器：整段文本直接编辑 + 应用/应用并保存。 */
Dialog {
    id: root

    property string heading: "原始配置"
    property string subtitle: ""
    property string initialText: ""
    property bool readOnly: false

    signal applyText(string text)
    signal applyAndSave(string text)

    modal: true
    padding: 0
    anchors.centerIn: Overlay.overlay
    width: Math.min(860, parent ? parent.width - 96 : 860)
    height: Math.min(640, parent ? parent.height - 96 : 640)
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle {
        color: Md3.alpha(Theme.colors.scrim, 0.4)
    }

    background: Rectangle {
        radius: Md3.shape.large
        color: Theme.colors.surfaceContainerHigh
    }

    contentItem: ColumnLayout {
        spacing: Md3.space.md

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.margins: Md3.space.lg
            Layout.bottomMargin: 0
            spacing: Md3.space.md

            MdIcon {
                name: "code"
                size: 22
                color: Theme.colors.primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                spacing: 2

                MdText {
                    role: "titleLarge"
                    text: root.heading
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                MdText {
                    visible: root.subtitle.length > 0
                    role: "bodySmall"
                    tone: "variant"
                    text: root.subtitle
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            MdIconButton {
                iconName: "close"
                tooltip: "关闭"
                onClicked: root.close()
            }
        }

        MdCodeField {
            id: editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Md3.space.lg
            Layout.rightMargin: Md3.space.lg
            minHeight: 320
            readOnly: root.readOnly
            text: root.initialText
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.margins: Md3.space.lg
            Layout.topMargin: 0
            spacing: Md3.space.sm

            MdText {
                role: "labelSmall"
                tone: "variant"
                text: editor.text.length + " 字符"
            }

            Item { Layout.fillWidth: true }

            MdButton {
                text: "取消"
                variant: "text"
                onClicked: root.close()
            }

            MdButton {
                text: "应用"
                variant: "tonal"
                visible: !root.readOnly
                onClicked: {
                    root.applyText(editor.text);
                    root.close();
                }
            }

            MdButton {
                text: "应用并保存"
                variant: "filled"
                visible: !root.readOnly
                onClicked: {
                    root.applyAndSave(editor.text);
                    root.close();
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: root.visible && !root.readOnly
        onActivated: {
            root.applyAndSave(editor.text);
            root.close();
        }
    }

    function openWith(text) {
        root.initialText = text;
        root.open();
    }
}
