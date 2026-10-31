import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 首页：状态总览 + 环境检测 + 组件信息 + 最近任务 + 快捷操作。 */
Item {
    id: page

    property var host

    readonly property bool wide: page.width >= 1180

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight + Md3.space.xl * 2
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MdScrollBar { }

        ColumnLayout {
            id: content
            width: Math.min(1100, page.width - Md3.space.xl * 2)
            x: Md3.space.xl
            y: Md3.space.lg
            spacing: Md3.space.xl

            MdBanner {
                Layout.fillWidth: true
                visible: !EnvReport.hasReport
                status: "info"
                text: "还没有环境检测结果。运行一次检测可以看到组件、运行器与依赖的完整状态。"
                actionText: "立即检测"
                onActionClicked: Adapter.checkEnvironment()
            }

            // 状态卡
            GridLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                columns: page.wide ? 4 : 2
                columnSpacing: Md3.space.md
                rowSpacing: Md3.space.md

                MdStatCard {
                    Layout.fillWidth: true
                    label: "应用版本"
                    value: "v" + App.appVersion
                    caption: "Qt " + App.qtVersion
                    status: "primary"
                    iconName: "about"
                }

                MdStatCard {
                    Layout.fillWidth: true
                    label: "组件提交"
                    value: Runtime.commitShort.length > 0 ? Runtime.commitShort : "—"
                    caption: Runtime.commitSubject.length > 0 ? Runtime.commitSubject
                                                             : (Runtime.ready ? "已初始化" : "尚未初始化")
                    status: Runtime.dirty ? "warning" : "neutral"
                    iconName: "git"
                }

                MdStatCard {
                    Layout.fillWidth: true
                    label: "环境检测"
                    value: EnvReport.hasReport
                           ? EnvReport.requiredPassed + " / " + EnvReport.requiredTotal
                           : "—"
                    caption: EnvReport.hasReport
                             ? (EnvReport.requiredFailed > 0
                                ? EnvReport.requiredFailed + " 项未通过"
                                : "全部通过 · " + EnvReport.checkedAtText)
                             : "尚未检测"
                    status: !EnvReport.hasReport ? "neutral"
                            : (EnvReport.requiredFailed > 0 ? "error"
                               : (EnvReport.warnings > 0 ? "warning" : "success"))
                    iconName: "shield"
                }

                MdStatCard {
                    Layout.fillWidth: true
                    label: "CLI"
                    value: Adapter.cliVerified ? "可用" : "未验证"
                    caption: Runtime.ready ? "组件已就绪" : "组件未就绪"
                    status: Adapter.cliVerified ? "success" : "neutral"
                    iconName: "terminal"
                }
            }

            // 主体两栏
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                spacing: Md3.space.lg

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 100000
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: page.wide ? content.width * 0.62 : content.width
                    spacing: Md3.space.lg

                    // 环境检测
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.sm

                            MdSectionHeader {
                                title: "环境检测"
                                caption: EnvReport.hasReport
                                         ? "检测于 " + EnvReport.checkedAtText
                                         : "尚未检测"

                                MdButton {
                                    text: "重新检测"
                                    variant: "text"
                                    onClicked: Adapter.checkEnvironment()
                                }
                            }

                            MdBanner {
                                Layout.fillWidth: true
                                visible: EnvReport.warnings > 0
                                status: "warning"
                                text: EnvReport.warnings + " 项警告，展开下面的分组查看详情。"
                            }

                            Repeater {
                                model: EnvReport.groups

                                delegate: MdExpansionPanel {
                                    Layout.fillWidth: true
                                    title: modelData.title
                                    subtitle: (modelData.items ? modelData.items.length : 0) + " 项"
                                    expanded: index === 0

                                    Column {
                                        width: parent.width
                                        spacing: 6

                                        Repeater {
                                            model: modelData.items

                                            delegate: RowLayout {
                                                width: parent.width
                                                spacing: Md3.space.sm

                                                MdIcon {
                                                    name: modelData.status === "ok" ? "check-circle"
                                                          : (modelData.status === "warn" ? "warning" : "error")
                                                    size: 16
                                                    color: modelData.status === "ok" ? Theme.colors.success
                                                           : (modelData.status === "warn" ? Theme.colors.warning
                                                                                          : Theme.colors.error)
                                                }

                                                MdText {
                                                    role: "bodySmall"
                                                    text: modelData.name
                                                    Layout.preferredWidth: 150
                                                    elide: Text.ElideRight
                                                }

                                                MdText {
                                                    role: "bodySmall"
                                                    mono: true
                                                    tone: "variant"
                                                    text: modelData.detail
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideMiddle
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MdEmptyState {
                                Layout.fillWidth: true
                                visible: !EnvReport.hasReport
                                iconName: "shield"
                                title: "还没有检测结果"
                                description: "检测会读取组件目录、运行器与依赖状态。"
                                actionText: "开始检测"
                                onActionClicked: Adapter.checkEnvironment()
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 100000
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: page.wide ? content.width * 0.38 : content.width
                    spacing: Md3.space.xl

                    // 组件信息
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.xs

                            MdSectionHeader {
                                title: "上游组件"
                                MdTag {
                                    text: Runtime.branch.length > 0 ? Runtime.branch : "—"
                                    status: "neutral"
                                }
                            }

                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "提交"
                                value: Runtime.commitShort.length > 0 ? Runtime.commitShort : "尚未初始化"
                                mono: true
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "工作区"
                                value: Runtime.dirty ? "有未提交改动" : "干净"
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "更新"
                                value: Runtime.updateAvailable
                                       ? "落后 " + Runtime.behindCount + " 个提交"
                                       : "已是最新"
                                mono: false
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "目录"
                                value: Runtime.runtimePath
                                mono: true
                                copyable: true
                                onCopyRequested: AppControl.copyToClipboard(Runtime.runtimePath)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100000
                                Layout.topMargin: Md3.space.sm
                                spacing: Md3.space.sm

                                MdButton {
                                    text: "检查更新"
                                    variant: "tonal"
                                    iconName: "refresh"
                                    onClicked: {
                                        Runtime.checkForUpdates();
                                        if (page.host) {
                                            page.host.navigate("diagnostics");
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    // 最近任务
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.xs

                            MdSectionHeader {
                                title: "最近任务"

                                MdButton {
                                    text: "全部"
                                    variant: "text"
                                    onClicked: if (page.host) page.host.navigate("tasks")
                                }
                            }

                            Repeater {
                                model: Tasks.recentTasks.slice(0, 5)

                                delegate: MdListItem {
                                    Layout.fillWidth: true
                                    interactive: true
                                    headline: modelData.label
                                    supporting: modelData.kind + " · " + modelData.durationText
                                    trailingText: modelData.stateText
                                    status: modelData.active ? "primary"
                                            : (modelData.errorSummary && modelData.errorSummary.length > 0
                                               ? "error" : "success")
                                    onClicked: if (page.host) page.host.navigate("tasks")
                                }
                            }

                            MdText {
                                Layout.fillWidth: true
                                visible: Tasks.recentTasks.length === 0
                                role: "bodySmall"
                                tone: "variant"
                                text: "还没有任务记录。"
                            }
                        }
                    }

                    // 快捷操作
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.sm

                            MdSectionHeader { title: "快捷操作" }

                            MdButton {
                                Layout.fillWidth: true
                                text: "启动游戏"
                                variant: "filled"
                                iconName: "play"
                                onClicked: if (page.host) page.host.navigate("games")
                            }
                            MdButton {
                                Layout.fillWidth: true
                                text: "编辑配置"
                                variant: "tonal"
                                iconName: "config"
                                onClicked: if (page.host) page.host.navigate("config")
                            }
                            MdButton {
                                Layout.fillWidth: true
                                text: "验证 CLI"
                                variant: "outlined"
                                iconName: "terminal"
                                onClicked: Adapter.verifyCli()
                            }
                        }
                    }
                }
            }
        }
    }
}
