import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 确认对话框：在 MdDialog 之上组合出「标题 + 多行说明 + 取消/确认」。
 *
 * 冻结 API：
 *   heading / message / confirmText / cancelText / danger
 *   accepted() / rejected()
 *   open() / close()
 *
 * 行为：确认 → accepted() 并关闭；取消 / ESC / 点遮罩 → rejected() 并关闭。
 * danger=true 时确认按钮用 filled + danger，否则 tonal；取消用 text。
 * message 的多行（\n\n 分段）原样保留。
 */
MdDialog {
    id: root

    property string message: ""
    property string confirmText: "确定"
    property string cancelText: "取消"
    property bool danger: false

    signal accepted()
    signal rejected()

    // 一次「决策」只发一次信号：关闭若是 ESC / 点遮罩触发的，就补发 rejected()
    property bool _decided: false

    iconName: root.danger ? "warning" : ""

    function accept() {
        if (root._decided) {
            return;
        }
        root._decided = true;
        root.close();
        root.accepted();
    }

    function reject() {
        if (root._decided) {
            return;
        }
        root._decided = true;
        root.close();
        root.rejected();
    }

    onOpened: root._decided = false
    onClosed: {
        if (!root._decided) {
            root._decided = true;
            root.rejected();
        }
    }

    MdText {
        visible: root.message.length > 0
        Layout.fillWidth: true
        role: "bodyMedium"
        tone: "variant"
        text: root.message
        wrapMode: Text.WordWrap
    }

    actions: [
        MdButton {
            text: root.cancelText
            variant: "text"
            onClicked: root.reject()
        },
        MdButton {
            text: root.confirmText
            variant: root.danger ? "filled" : "tonal"
            danger: root.danger
            onClicked: root.accept()
        }
    ]
}
