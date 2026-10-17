import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 任务中心：实时日志、退出码、取消、历史与清理 */
Item {
    id: page

    property var host

    function taskStateKind(state) {
        if (state === "succeeded") return "state";
        if (state === "failed") return "danger";
        if (state === "canceled" || state === "timeout") return "warn";
        return "signal";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        PageHeader {
            Layout.fillWidth: true
            index: "03"
            title: "任务"
            english: "TASKS"
            subtitle: "EXECUTION LOG / EXIT CODES / CANCELLATION"

            ArkButton {
                text: "取消当前任务"
                implicitHeight: 40
                danger: true
                enabled: Tasks.currentTask !== null && Tasks.currentTask.active
                onClicked: Tasks.cancelTask(Tasks.currentTask.id)
            }

            ArkButton {
                text: "清空历史"
                implicitHeight: 40
                ghost: true
                enabled: Tasks.tasks.count > 0
                onClicked: clearDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            ChamferedPanel {
                Layout.preferredWidth: 360
                Layout.fillHeight: true
                contentMargin: 14
                cut: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    SectionHeader {
                        Layout.fillWidth: true
                        index: "01"
                        english: "QUEUE"
                        title: "任务列表"
                    }

                    ListView {
                        id: taskList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: Tasks.tasks
                        spacing: 0
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: TaskItem {
                            width: taskList.width
                            indexText: (index + 1).toString().padStart(2, "0")
                            label: label
                            state: state
                            stateText: stateText
                            detail: kind
                            whenText: startedAt ? Qt.formatDateTime(startedAt, "MM-dd hh:mm:ss") : ""
                            durationText: durationText
                            exitCode: exitCode
                            hasExitCode: hasExitCode
                            active: active
                            selected: Tasks.currentTask !== null && Tasks.currentTask.id === taskId
                            onClicked: Tasks.select(taskId)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: taskList.count === 0
                        text: "尚无任务。"
                        color: Theme.colors.muted
                        font.family: App.uiFontFamily
                        font.pixelSize: 11
                    }

                    MicroLabel {
                        label: "HISTORY 200 / DISK LOGS KEPT"
                        color: Theme.colors.disabled
                        microSize: 8
                        tracking: 0.8
                    }
                }
            }

            ChamferedPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentMargin: 16
                cut: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    SectionHeader {
                        Layout.fillWidth: true
                        index: "02"
                        english: "OUTPUT"
                        title: "执行日志"
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        visible: Tasks.currentTask !== null

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: Tasks.currentTask ? Tasks.currentTask.label : ""
                                    color: Theme.colors.paper
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                ArkTag {
                                    visible: Tasks.currentTask !== null
                                    text: Tasks.currentTask ? Tasks.currentTask.stateText : ""
                                    kind: Tasks.currentTask ? page.taskStateKind(Tasks.currentTask.state)
                                                            : "neutral"
                                    implicitHeight: 20
                                }

                                ArkTag {
                                    visible: Tasks.currentTask !== null && Tasks.currentTask.hasExitCode
                                    text: Tasks.currentTask ? "EXIT " + Tasks.currentTask.exitCode : ""
                                    kind: Tasks.currentTask && Tasks.currentTask.exitCode === 0
                                          ? "neutral" : "danger"
                                    implicitHeight: 20
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                MicroLabel {
                                    Layout.fillWidth: true
                                    label: Tasks.currentTask ? Tasks.currentTask.command : ""
                                    color: Theme.colors.disabled
                                    microSize: 9
                                    tracking: 0.5
                                    elide: Text.ElideMiddle
                                }

                                MicroLabel {
                                    visible: Tasks.currentTask !== null
                                    label: Tasks.currentTask
                                           ? "START " + Qt.formatDateTime(Tasks.currentTask.startedAt, "yyyy-MM-dd hh:mm:ss")
                                             + " · " + Tasks.currentTask.durationText
                                           : ""
                                    color: Theme.colors.muted
                                    microSize: 9
                                    tracking: 0.6
                                }

                                ArkButton {
                                    text: "复制命令"
                                    implicitHeight: 32
                                    ghost: true
                                    font.pixelSize: 9
                                    visible: Tasks.currentTask !== null
                                    onClicked: AppControl.copyToClipboard(Tasks.currentTask.command)
                                }

                                ArkButton {
                                    text: "打开日志文件"
                                    implicitHeight: 32
                                    ghost: true
                                    font.pixelSize: 9
                                    visible: Tasks.currentTask !== null
                                    onClicked: AppControl.openFileInFolder(Tasks.currentTask.logPath)
                                }
                            }
                        }
                    }

                    LogView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: "STDOUT / STDERR"
                        busy: Tasks.currentTask !== null && Tasks.currentTask.active
                        logModel: Tasks.currentTask ? Tasks.currentTask.log : null
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Tasks.currentTask === null
                        text: "选择一个任务查看输出，或从「游戏」页面启动一个游戏。"
                        color: Theme.colors.muted
                        font.family: App.uiFontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: clearDialog
        title: "清空任务历史？"
        message: "只会删除任务历史列表（最多 200 条）与索引；磁盘上的任务日志文件不会被删除。"
        confirmText: "清空历史"
        danger: true
        onAccepted: Tasks.clearFinishedHistory()
    }
}
