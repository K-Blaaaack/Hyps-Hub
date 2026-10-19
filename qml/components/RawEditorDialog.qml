import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/*
 * 大窗口原始配置编辑器：约 1200×800（随窗口收缩），内部 CodeEditor 双向滚动。
 * 父页面通过 openWith(...) 传入标题、路径与文本；applyRequested / saveRequested
 * 由父页面执行校验与保存。
 */
Popup {
    id: dialog

    property string title: "原始配置"
    property string subtitle: ""
    property string filePath: ""
    property string editorText: ""
    property bool readOnly: false

    signal applyRequested(string text)
    signal saveRequested(string text)

    property bool edited: editor.text !== dialog.editorText

    modal: true
    focus: true
    padding: 24
    closePolicy: Popup.NoAutoClose
    width: Math.min(1200, Overlay.overlay ? Overlay.overlay.width - 100 : 1200)
    height: Math.min(780, Overlay.overlay ? Overlay.overlay.height - 120 : 780)
    anchors.centerIn: Overlay.overlay

    background: ChamferedPanel {
        cut: 14
        contentMargin: 0
    }

    function openWith(dialogTitle, path, content, lock) {
        title = dialogTitle;
        filePath = path;
        editorText = content;
        readOnly = lock === true;
        open();
    }

    function currentText() {
        return editor.text;
    }

    function markApplied() {
        editorText = editor.text;
    }

    function requestClose() {
        if (dialog.edited && !dialog.readOnly) {
            discardDialog.open();
        } else {
            close();
        }
    }

    onOpened: {
        editor.text = editorText;
        editor.forceActiveFocus();
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: dialog.visible && !dialog.readOnly && !discardDialog.visible
        onActivated: dialog.saveRequested(editor.text)
    }

    Shortcut {
        sequence: "Escape"
        enabled: dialog.visible && !discardDialog.visible
        onActivated: dialog.requestClose()
    }

    contentItem: ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MicroLabel {
                label: dialog.title
                color: Theme.colors.signal
                microSize: 11
                tracking: 1.6
            }

            Item { Layout.fillWidth: true }

            MicroLabel {
                visible: dialog.readOnly
                label: "READ ONLY"
                color: Theme.colors.warn
                microSize: 9
                tracking: 1.2
            }

            MicroLabel {
                label: "Ctrl+S 保存"
                color: Theme.colors.disabled
                microSize: 8
                tracking: 0.8
            }
        }

        Text {
            Layout.fillWidth: true
            visible: dialog.subtitle.length > 0
            text: dialog.subtitle
            color: Theme.colors.muted
            font.family: App.uiFontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        InfoRow {
            Layout.fillWidth: true
            label: "文件"
            value: dialog.filePath
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.rule
        }

        CodeEditor {
            id: editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 320
            readOnly: dialog.readOnly
            placeholderText: "在此编辑配置文件；支持横向与纵向滚动"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ArkButton {
                text: "应用文本"
                implicitHeight: 40
                enabled: !dialog.readOnly
                onClicked: dialog.applyRequested(editor.text)
            }

            ArkButton {
                text: "应用并保存"
                implicitHeight: 40
                primary: true
                enabled: !dialog.readOnly
                onClicked: dialog.saveRequested(editor.text)
            }

            Item { Layout.fillWidth: true }

            MicroLabel {
                label: "保存前会创建 .bak.<时间戳> 备份"
                color: Theme.colors.disabled
                microSize: 8
                tracking: 0.8
            }

            ArkButton {
                text: "关闭"
                implicitHeight: 40
                ghost: true
                onClicked: dialog.requestClose()
            }
        }
    }

    ConfirmDialog {
        id: discardDialog
        title: "放弃未保存的编辑？"
        message: "原始编辑器中有修改尚未应用。关闭会丢弃这些修改。"
        confirmText: "放弃修改"
        cancelText: "继续编辑"
        danger: true
        onAccepted: dialog.close()
    }
}
