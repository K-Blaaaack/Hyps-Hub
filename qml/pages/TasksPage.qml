import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 任务页：左侧任务列表 + 右侧详情与日志。 */
Item {
    id: page

    property var host

    RowLayout {
        anchors.fill: parent
        // 和单栏页统一：左右 24、上 16，切页时左边缘不跳
        anchors.margins: Md3.space.xl
        anchors.topMargin: Md3.space.lg
        spacing: Md3.space.lg

        // 左：列表（标题栏放进面板内，左右两栏顶边才对得齐）
        Rectangle {
            Layout.preferredWidth: 340
            Layout.minimumWidth: 340
            Layout.maximumWidth: 340
            Layout.fillHeight: true
            radius: Md3.shape.medium
            color: Theme.colors.surfaceContainerLow
            border.width: 1
            border.color: Theme.colors.outlineVariant
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Md3.space.sm
                spacing: Md3.space.sm

                RowLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 100000
                    Layout.leftMargin: 8
                    Layout.rightMargin: 4
                    spacing: Md3.space.sm

                    MdText { role: "titleSmall"; text: "任务" }

                    MdTag {
                        text: Tasks.activeCount > 0 ? Tasks.activeCount + " 运行中" : "空闲"
                        status: Tasks.activeCount > 0 ? "primary" : "neutral"
                    }

                    Item { Layout.fillWidth: true }

                    MdIconButton {
                        iconName: "stop"
                        size: 32
                        iconSize: 18
                        tooltip: "取消全部"
                        enabled: Tasks.activeCount > 0
                        onClicked: Tasks.cancelActive()
                    }

                    MdIconButton {
                        iconName: "trash"
                        size: 32
                        iconSize: 18
                        tooltip: "清空历史"
                        onClicked: clearDialog.open()
                    }
                }

                ListView {
                    id: taskList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Tasks.tasks
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: MdScrollBar { }

                    delegate: MdTaskItem {
                        width: taskList.width
                        taskId: model.taskId
                        label: model.label
                        stateText: model.stateText
                        kind: model.kind
                        durationText: model.durationText
                        errorSummary: model.errorSummary
                        active: model.active
                        selected: Tasks.currentTask && Tasks.currentTask.id === model.taskId
                        onClicked: {
                            Tasks.select(model.taskId);
                            Tasks.loadCurrentLog();
                        }
                    }

                    MdText {
                        anchors.centerIn: parent
                        visible: taskList.count === 0
                        role: "bodySmall"
                        tone: "variant"
                        text: "还没有任务"
                    }
                }
            }
        }

        // 右：详情
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.fillHeight: true
            spacing: Md3.space.lg

            MdCard {
                Layout.fillWidth: true
                variant: "outlined"
                visible: Tasks.currentTask !== null && Tasks.currentTask !== undefined

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdText {
                            Layout.fillWidth: true
                            role: "titleLarge"
                            text: Tasks.currentTask ? Tasks.currentTask.label : ""
                            elide: Text.ElideRight
                        }

                        MdTag {
                            text: Tasks.currentTask ? Tasks.currentTask.stateText : ""
                            status: {
                                if (!Tasks.currentTask) {
                                    return "neutral";
                                }
                                if (Tasks.currentTask.active) {
                                    return "primary";
                                }
                                const s = Tasks.currentTask.state;
                                if (s === "succeeded") {
                                    return "success";
                                }
                                if (s === "failed" || s === "timeout") {
                                    return "error";
                                }
                                return "neutral";
                            }
                        }

                        MdButton {
                            text: "取消任务"
                            variant: "outlined"
                            danger: true
                            iconName: "stop"
                            visible: Tasks.currentTask ? Tasks.currentTask.cancelable : false
                            onClicked: if (Tasks.currentTask) Tasks.cancelTask(Tasks.currentTask.id)
                        }
                    }

                    MdText {
                        Layout.fillWidth: true
                        role: "bodySmall"
                        tone: "variant"
                        text: {
                            if (!Tasks.currentTask) {
                                return "";
                            }
                            const t = Tasks.currentTask;
                            let line = t.kind + " · " + t.durationText;
                            if (t.hasExitCode) {
                                line += " · 退出码 " + t.exitCode;
                            }
                            return line;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdText {
                            Layout.fillWidth: true
                            role: "bodySmall"
                            mono: true
                            tone: "variant"
                            text: Tasks.currentTask ? Tasks.currentTask.command : ""
                            elide: Text.ElideMiddle
                        }

                        MdIconButton {
                            iconName: "copy"
                            size: 32
                            iconSize: 16
                            tooltip: "复制命令"
                            onClicked: if (Tasks.currentTask) AppControl.copyToClipboard(Tasks.currentTask.command)
                        }
                    }

                    MdBanner {
                        Layout.fillWidth: true
                        visible: Tasks.currentTask ? Tasks.currentTask.errorSummary.length > 0 : false
                        status: "error"
                        text: Tasks.currentTask ? Tasks.currentTask.errorSummary : ""
                    }

                    MdProgressLinear {
                        Layout.fillWidth: true
                        visible: Tasks.currentTask ? Tasks.currentTask.active : false
                        value: -1
                        thickness: 3
                    }
                }
            }

            MdLogView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                logModel: Tasks.currentTask ? Tasks.currentTask.log : null
                busy: Tasks.currentTask ? Tasks.currentTask.active : false
                title: "输出"
                onClearRequested: Tasks.clearCurrentLogView()
            }

            MdEmptyState {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Tasks.currentTask === null || Tasks.currentTask === undefined
                iconName: "tasks"
                title: "还没有选中任务"
                description: "从游戏页启动一个游戏，运行过程会实时出现在这里。"
                actionText: "去游戏页"
                onActionClicked: if (page.host) page.host.navigate("games")
            }
        }
    }

    MdConfirmDialog {
        id: clearDialog
        heading: "清空任务历史？"
        message: "已结束的任务记录会被移除，正在运行的任务不受影响。"
        confirmText: "清空"
        danger: true
        onAccepted: Tasks.clearFinishedHistory()
    }

    Connections {
        target: Tasks
        function onLastErrorChanged() {
            if (Tasks.lastError.length > 0 && page.host) {
                page.host.showToast(Tasks.lastError);
            }
        }
    }
}
