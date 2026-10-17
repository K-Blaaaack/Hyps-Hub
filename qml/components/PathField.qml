import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/* 路径输入：等宽文本 + 方角输入框 + 浏览按钮 */
Item {
    id: root

    property string value: ""
    property string placeholder: ""
    property string mode: "file" // file | dir
    property string nameFilter: "*"
    property string dialogTitle: "选择路径"

    signal committed(string value)

    implicitHeight: 40

    function sync() {
        if (!input.activeFocus) {
            input.text = root.value;
        }
    }

    Component.onCompleted: sync()
    onValueChanged: sync()

    RowLayout {
        anchors.fill: parent
        spacing: 8

        TextField {
            id: input
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: root.placeholder
            color: Theme.colors.paper2
            placeholderTextColor: Theme.colors.disabled
            selectionColor: Theme.colors.signal
            selectedTextColor: Theme.colors.onSignal
            font.family: App.monoFontFamily
            font.pixelSize: 12
            leftPadding: 10
            rightPadding: 10
            selectByMouse: true
            onEditingFinished: root.committed(text)

            background: Rectangle {
                color: Theme.colors.ink
                border.width: 1
                border.color: input.activeFocus ? Theme.colors.signal : Theme.colors.line
            }
        }

        ArkButton {
            text: "浏览"
            implicitHeight: 40
            onClicked: picker.open()
        }
    }

    FilePicker {
        id: picker
        mode: root.mode
        nameFilter: root.nameFilter
        dialogTitle: root.dialogTitle
        startPath: root.value.length > 0 ? root.value : ""
        onAccepted: function (path) {
            root.committed(path);
        }
    }
}
