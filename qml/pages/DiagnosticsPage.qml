import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 诊断页：环境报表、上游更新、诊断命令、导出诊断包、原始报表。 */
Item {
    id: page

    property var host
    property string exportDir: Diag.defaultExportDirectory()

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

            // 环境报表
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "环境报表"
                        caption: EnvReport.hasReport
                                 ? EnvReport.summaryText + " · " + EnvReport.checkedAtText
                                 : "尚未检测"

                        MdButton {
                            text: "重新检测"
                            variant: "text"
                            onClicked: Adapter.checkEnvironment()
                        }
                        MdButton {
                            text: "验证 CLI"
                            variant: "text"
                            onClicked: Adapter.verifyCli()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdTag {
                            text: "通过 " + EnvReport.requiredPassed + " / " + EnvReport.requiredTotal
                            status: EnvReport.requiredFailed > 0 ? "error" : "success"
                        }
                        MdTag {
                            visible: EnvReport.warnings > 0
                            text: "警告 " + EnvReport.warnings
                            status: "warning"
                        }
                        MdTag {
                            visible: EnvReport.configWarnings > 0
                            text: "配置警告 " + EnvReport.configWarnings
                            status: "warning"
                        }
                        MdTag {
                            text: Adapter.cliVerified ? "CLI 已验证" : "CLI 未验证"
                            status: Adapter.cliVerified ? "success" : "neutral"
                        }
                        Item { Layout.fillWidth: true }
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
                                            Layout.preferredWidth: 170
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

            // 上游更新
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "上游更新"
                        caption: Runtime.updateStatusText

                        MdTag {
                            text: Runtime.updateAvailable ? "有更新" : "最新"
                            status: Runtime.updateAvailable ? "primary" : "success"
                        }
                    }

                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "当前提交"
                        value: Runtime.commitShort.length > 0
                               ? Runtime.commitShort + "  " + Runtime.commitSubject
                               : "—"
                        mono: true
                    }
                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "上游提交"
                        value: Runtime.upstreamCommit.length > 0
                               ? Runtime.upstreamCommit + "  " + Runtime.upstreamSubject
                               : "—"
                        mono: true
                    }
                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "落后 / 领先"
                        value: Runtime.behindCount + " / " + Runtime.aheadCount
                        mono: true
                    }

                    MdProgressLinear {
                        Layout.fillWidth: true
                        visible: Runtime.busy
                        value: Runtime.progress >= 0 && Runtime.progress <= 1 ? Runtime.progress : -1
                    }

                    MdText {
                        Layout.fillWidth: true
                        visible: Runtime.busy && Runtime.progressText.length > 0
                        role: "bodySmall"
                        tone: "variant"
                        text: Runtime.progressText
                    }

                    MdBanner {
                        Layout.fillWidth: true
                        visible: Runtime.errorMessage.length > 0
                        status: "error"
                        text: Runtime.errorMessage
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdButton {
                            text: "检查更新"
                            variant: "tonal"
                            iconName: "refresh"
                            enabled: !Runtime.busy
                            onClicked: Runtime.checkForUpdates()
                        }
                        MdButton {
                            text: "应用更新"
                            variant: "filled"
                            iconName: "download"
                            enabled: Runtime.updateAvailable && !Runtime.busy
                            onClicked: Runtime.applyUpdate()
                        }
                        MdButton {
                            visible: Runtime.busy
                            text: "取消"
                            variant: "outlined"
                            iconName: "stop"
                            onClicked: Runtime.cancelOperation()
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        visible: Runtime.logLines.length > 0
                        radius: Md3.shape.small
                        color: Theme.colors.codeSurface
                        border.width: 1
                        border.color: Theme.colors.outlineVariant
                        clip: true

                        ListView {
                            id: updateLog
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true
                            model: Runtime.logLines
                            ScrollBar.vertical: MdScrollBar { }
                            onCountChanged: Qt.callLater(function () { updateLog.positionViewAtEnd() })

                            delegate: MdText {
                                width: updateLog.width
                                role: "bodySmall"
                                mono: true
                                text: modelData
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }
            }

            // 诊断命令
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.xs

                    MdSectionHeader {
                        title: "诊断命令"
                        caption: "命令在任务页执行，输出会实时出现"
                    }

                    Repeater {
                        model: Adapter.diagnosticActions

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Md3.space.md

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100000
                                spacing: 0

                                MdText {
                                    role: "bodyMedium"
                                    text: modelData.title
                                }
                                MdText {
                                    Layout.fillWidth: true
                                    role: "bodySmall"
                                    tone: "variant"
                                    text: modelData.description
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MdButton {
                                text: "运行"
                                variant: "outlined"
                                onClicked: {
                                    Adapter.runDiagnostic(modelData.id);
                                    if (page.host) {
                                        page.host.navigate("tasks");
                                    }
                                }
                            }
                        }
                    }

                    MdText {
                        Layout.fillWidth: true
                        visible: Adapter.diagnosticActions.length === 0
                        role: "bodySmall"
                        tone: "variant"
                        text: "组件未就绪，暂时没有可用的诊断命令。"
                    }
                }
            }

            // 导出诊断包
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "导出诊断包"
                        caption: "打包环境报表、配置与最近日志，便于排查问题"
                    }

                    MdPathField {
                        Layout.fillWidth: true
                        label: "导出目录"
                        mode: "dir"
                        text: page.exportDir
                        onCommitted: function (path) { page.exportDir = path }
                    }

                    MdBanner {
                        Layout.fillWidth: true
                        visible: Diag.lastExportError.length > 0
                        status: "error"
                        text: Diag.lastExportError
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdButton {
                            text: "导出"
                            variant: "filled"
                            iconName: "download"
                            onClicked: {
                                const result = Diag.exportBundle(page.exportDir);
                                if (result && result.ok) {
                                    if (page.host) {
                                        page.host.showToast("已导出：" + result.path);
                                    }
                                } else if (page.host) {
                                    page.host.showToast("导出失败：" + (result && result.error
                                                                        ? result.error
                                                                        : Diag.lastExportError));
                                }
                            }
                        }

                        MdText {
                            Layout.fillWidth: true
                            role: "bodySmall"
                            mono: true
                            tone: "variant"
                            text: Diag.lastExportPath
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // 原始报表
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "原始报表"
                        caption: "hyps doctor 的原始输出"
                    }

                    MdCodeBlock {
                        Layout.fillWidth: true
                        maxHeight: 280
                        text: EnvReport.rawText.length > 0 ? EnvReport.rawText : "（还没有报表）"
                    }
                }
            }
        }
    }
}
