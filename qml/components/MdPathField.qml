import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* 路径输入：等宽文本框 + 浏览按钮。 */
Item {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property string text: ""
    property string label: ""
    property string placeholder: ""
    property string mode: "file"
    property string nameFilter: "*"
    property string dialogTitle: "选择路径"

    signal committed(string path)

    implicitHeight: Md3.size.textField

    function sync() {
        if (!input.activeFocus) {
            input.text = root.text;
        }
    }

    Component.onCompleted: sync()
    onTextChanged: sync()

    // 用 RowLayout 而不是 Row：Row 会忽略子项的 anchors，浏览按钮会贴在顶部，
    // 和输入框（含浮动标签）差 6px 看起来就是错位。
    RowLayout {
        anchors.fill: parent
        spacing: Md3.space.sm

        MdTextField {
            id: input
            Layout.fillWidth: true
            Layout.fillHeight: true
            monospace: true
            label: root.label
            placeholderText: root.placeholder
            text: root.text
            onEditingFinished: root.committed(text)
            onTextEdited: root.text = text
        }

        MdButton {
            id: browse
            text: "浏览"
            variant: "tonal"
            Layout.alignment: Qt.AlignVCenter
            onClicked: picker.open()
        }
    }

    MdFilePicker {
        id: picker
        mode: root.mode
        nameFilter: root.nameFilter
        dialogTitle: root.dialogTitle.length > 0 ? root.dialogTitle : root.label
        startPath: root.text
        onSelected: function (path) {
            root.text = path;
            root.committed(path);
        }
    }
}
