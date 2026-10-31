import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/*
 * MdDialog / MdConfirmDialog / MdSnackbar 组件画廊（开发用，不进 qrc）。
 * 启动后自动弹出确认对话框与 Snackbar，方便截图核对 MD3 外观与遮罩。
 */
ApplicationWindow {
    id: win
    visible: true
    width: 1200
    height: 900
    color: Theme.colors.surface

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        MdText { role: "headlineSmall"; text: "MD3 对话框 / Snackbar" }
        MdText {
            role: "bodyMedium"
            tone: "variant"
            text: "启动后自动打开确认对话框与 Snackbar；下面的按钮可逐个复现各状态。"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 12
            MdButton { text: "基本对话框"; variant: "filled"; iconName: "info"; onClicked: infoDialog.open() }
            MdButton { text: "确认框"; variant: "tonal"; onClicked: confirmDialog.open() }
            MdButton { text: "安全确认框"; variant: "outlined"; onClicked: safeDialog.open() }
            MdButton { text: "长正文（滚动）"; variant: "text"; onClicked: longDialog.open() }
            MdButton { text: "显示 Snackbar"; variant: "text"; onClicked: snackbar.show("配置已保存") }
        }

        MdCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                MdText { role: "titleMedium"; text: "最近动作" }
                MdText { id: status; role: "bodyMedium"; tone: "variant"; text: "（还没有动作）" }
                MdText { role: "bodySmall"; tone: "variant"; text: "确认/取消/Snackbar 动作都会写在这里。" }
                Item { Layout.fillHeight: true }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ---- 基本对话框 -------------------------------------------------------
    MdDialog {
        id: infoDialog
        heading: "关于 Hyps Hub"
        iconName: "info"

        MdText {
            Layout.fillWidth: true
            role: "bodyMedium"
            tone: "variant"
            wrapMode: Text.WordWrap
            text: "Hyps Hub 是一个把 DeepSeek Harness 的配置、任务与诊断收在一处的桌面工具。"
        }

        actions: [
            MdButton {
                text: "关闭"
                variant: "text"
                onClicked: {
                    infoDialog.close();
                    status.text = "基本对话框已关闭";
                }
            },
            MdButton {
                text: "打开配置"
                variant: "tonal"
                iconName: "config"
                onClicked: {
                    infoDialog.close();
                    status.text = "基本对话框：打开配置";
                }
            }
        ]
    }

    // ---- 危险确认 ---------------------------------------------------------
    MdConfirmDialog {
        id: confirmDialog
        heading: "取消正在运行的任务？"
        message: "任务「DeepSeek Harness · 构建」仍在运行。\n\n"
                 + "取消会向整个进程组发送终止信号，已产生的日志会保留，"
                 + "但这一轮构建需要从头再来。\n\n确定取消吗？"
        confirmText: "取消任务"
        cancelText: "继续等待"
        danger: true
        onAccepted: status.text = "确认框：accepted()（取消任务）"
        onRejected: status.text = "确认框：rejected()（继续等待）"
    }

    // ---- 普通确认 ---------------------------------------------------------
    MdConfirmDialog {
        id: safeDialog
        heading: "保存配置？"
        message: "保存后会立即写入 ~/.config/hyps-hub/config.json。"
        confirmText: "保存"
        cancelText: "取消"
        onAccepted: status.text = "安全确认框：accepted()（保存）"
        onRejected: status.text = "安全确认框：rejected()（取消）"
    }

    // ---- 长正文（触发 Flickable 滚动）-------------------------------------
    MdDialog {
        id: longDialog
        heading: "诊断输出"
        iconName: "terminal"

        MdText {
            Layout.fillWidth: true
            role: "bodyMedium"
            tone: "variant"
            wrapMode: Text.WordWrap
            text: "下面是一段很长的说明，用来验证正文超过 60% 屏高时会收进 Flickable 滚动，"
                 + "并且标题与底部操作区始终可见。\n\n"
                 + Array(12).join("这一行只是占位文字，用来把正文撑高；滚动条不会出现，"
                                  + "但可以用鼠标滚轮或触控板上下拖动。\n\n")
                 + "（结尾）"
        }

        actions: [
            MdButton {
                text: "关闭"
                variant: "text"
                onClicked: longDialog.close()
            }
        ]
    }

    // ---- Snackbar ---------------------------------------------------------
    MdSnackbar {
        id: snackbar
        actionText: "撤销"
        x: Math.round((win.width - width) / 2)
        y: win.height - height - 24
        onActionTriggered: status.text = "Snackbar：actionTriggered()（撤销）"
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            snackbar.show("配置已保存到 ~/.config/hyps-hub/config.json");
            confirmDialog.open();
        });
    }
}
