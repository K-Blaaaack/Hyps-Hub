import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 诊断：前置检查、环境报表、Hyps 组件更新、白名单命令与脱敏导出 */
Item {
    id: page

    property var host
    property bool showRaw: false
    property string exportDir: Diag.defaultExportDirectory()
    property bool networkCheckStarted: false

    function ensureNetworkCheck() {
        if (!page.networkCheckStarted && Runtime.ready
            && Runtime.networkStatus === "idle") {
            page.networkCheckStarted = true;
            Runtime.checkNetwork();
        }
    }

    Component.onCompleted: ensureNetworkCheck()

    Connections {
        target: Runtime
        function onStateChanged() { page.ensureNetworkCheck(); }
    }

    function runAction(actionId) {
        const task = Adapter.runDiagnostic(actionId);
        if (!task) {
            page.host.showToast("无法执行：" + Adapter.lastError);
            return;
        }
        Tasks.select(task.id);
        page.host.navigate("tasks");
    }

    function exportBundle() {
        const result = Diag.exportBundle(page.exportDir);
        if (result.ok) {
            page.host.showToast("诊断包已导出：" + result.path);
        } else {
            page.host.showToast("导出失败：" + result.error);
        }
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight + 44
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

        Item {
            width: scroll.width
            height: content.implicitHeight + 44

            ColumnLayout {
                id: content
                x: 24
                y: 20
                width: parent.width - 48
                spacing: 14

                PageHeader {
                    Layout.fillWidth: true
                    index: "05"
                    title: "诊断"
                    english: "DIAGNOSTICS"
                    subtitle: "REAL PROBES / COMPONENT UPDATE / SANITIZED EXPORT"

                    ArkButton {
                        text: "导出诊断包"
                        implicitHeight: 40
                        primary: true
                        onClicked: page.exportBundle()
                    }

                    ArkButton {
                        text: "打开日志目录"
                        implicitHeight: 40
                        ghost: true
                        onClicked: AppControl.openDirectory(App.logsDir)
                    }
                }

                // 前置检查
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: prereqColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10
                    accentColor: Theme.colors.signal

                    ColumnLayout {
                        id: prereqColumn
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "01"
                                english: "PREFLIGHT"
                                title: "GUI 前置检查"
                            }

                            ArkButton {
                                text: "重新检查"
                                implicitHeight: 34
                                ghost: true
                                onClicked: Runtime.refreshPrerequisites()
                            }

                            ArkButton {
                                text: "检查网络"
                                implicitHeight: 34
                                ghost: true
                                enabled: Runtime.networkStatus !== "checking"
                                onClicked: Runtime.checkNetwork()
                            }
                        }

                        Repeater {
                            model: Runtime.prerequisites

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 8
                                    height: 8
                                    color: modelData.ok ? Theme.colors.state : Theme.colors.danger
                                }

                                MicroLabel {
                                    Layout.preferredWidth: 92
                                    label: modelData.name
                                    color: Theme.colors.paper2
                                    microSize: 9
                                    tracking: 1.0
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.detail
                                    color: Theme.colors.muted
                                    font.family: App.monoFontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                }

                                MicroLabel {
                                    label: modelData.hint
                                    color: Theme.colors.disabled
                                    microSize: 8
                                    tracking: 0.6
                                }

                                ArkTag {
                                    text: modelData.ok ? "OK" : "NG"
                                    kind: modelData.ok ? "state" : "danger"
                                    implicitHeight: 18
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: Runtime.networkDetail.length > 0
                            text: Runtime.networkDetail
                            color: Runtime.networkStatus === "ok" ? Theme.colors.muted
                                 : (Runtime.networkStatus === "error" ? Theme.colors.danger
                                                                      : Theme.colors.muted)
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // 环境检测
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: envColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: envColumn
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "02"
                                english: "ENVIRONMENT"
                                title: "Hyps 环境检测"
                            }

                            ArkButton {
                                text: "重新检测"
                                implicitHeight: 34
                                enabled: Runtime.ready
                                onClicked: Adapter.checkEnvironment()
                            }

                            ArkButton {
                                text: page.showRaw ? "隐藏原始输出" : "原始输出"
                                implicitHeight: 34
                                ghost: true
                                onClicked: page.showRaw = !page.showRaw
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            MicroLabel {
                                label: EnvReport.hasReport ? EnvReport.summaryText : "尚未检测"
                                color: Theme.colors.paper2
                                microSize: 10
                                tracking: 0.6
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            MicroLabel {
                                label: EnvReport.checkedAtText
                                color: Theme.colors.disabled
                                microSize: 9
                                tracking: 0.6
                            }
                        }

                        Repeater {
                            model: EnvReport.groups

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Layout.topMargin: 4

                                MicroLabel {
                                    label: modelData.title
                                    color: Theme.colors.signal
                                    microSize: 9
                                    tracking: 1.4
                                }

                                Repeater {
                                    model: modelData.items

                                    delegate: RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            color: modelData.status === "ok" ? Theme.colors.state
                                                 : (modelData.status === "warn" ? Theme.colors.warn
                                                    : (modelData.status === "fail" ? Theme.colors.danger
                                                                                   : Theme.colors.muted))
                                        }

                                        Text {
                                            Layout.preferredWidth: 170
                                            text: modelData.name
                                            color: Theme.colors.paper2
                                            font.family: App.uiFontFamily
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.detail
                                            color: Theme.colors.muted
                                            font.family: App.monoFontFamily
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                            visible: page.showRaw
                            readOnly: true
                            text: EnvReport.rawText
                            color: Theme.colors.muted
                            font.family: App.monoFontFamily
                            font.pixelSize: 10
                            selectByMouse: true
                            wrapMode: TextArea.WrapAnywhere
                            background: Rectangle {
                                color: Theme.colors.codeBg
                                border.width: 1
                                border.color: Theme.colors.line
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !EnvReport.hasReport
                            text: "尚未运行环境检测。Hyps 组件就绪后点击「重新检测」。"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                // Hyps 组件更新
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: updateColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10
                    accentColor: Runtime.updateAvailable ? Theme.colors.signal : Theme.colors.line

                    ColumnLayout {
                        id: updateColumn
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "03"
                            english: "COMPONENT UPDATE"
                            title: "Hyps 组件更新"
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "当前提交"
                            value: Runtime.ready
                                   ? Runtime.commitShort + "  " + Runtime.commitSubject : "—"
                            wrap: true
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "当前分支"
                            value: Runtime.ready ? Runtime.branch + (Runtime.dirty ? "  （有未提交修改）" : "  （工作区干净）")
                                                 : "—"
                            valueColor: Runtime.dirty ? Theme.colors.warn : Theme.colors.paper2
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "上游提交"
                            value: Runtime.upstreamCommit.length > 0
                                   ? Runtime.upstreamCommit.substring(0, 12) + "  " + Runtime.upstreamSubject
                                   : "尚未检查"
                            wrap: true
                        }

                        ArkProgress {
                            Layout.fillWidth: true
                            visible: Runtime.state === "updating" || Runtime.state === "verifying"
                            indeterminate: Runtime.state === "updating"
                            value: Runtime.progress
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Runtime.updateStatusText
                            color: Runtime.updateAvailable ? Theme.colors.signal : Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: Runtime.updateAvailable && Runtime.dirty
                            text: "Hyps 组件存在未提交的修改，更新会被拒绝。Hyps Hub 不会执行 reset/clean，"
                                  + "请先在组件目录中手动处理这些修改。"
                            color: Theme.colors.warn
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ArkButton {
                                text: "检查更新"
                                implicitHeight: 38
                                enabled: Runtime.ready && !Runtime.busy
                                onClicked: Runtime.checkForUpdates()
                            }

                            ArkButton {
                                text: Runtime.behindCount > 0
                                      ? "快进更新（" + Runtime.behindCount + "）" : "更新"
                                implicitHeight: 38
                                primary: true
                                enabled: Runtime.updateAvailable && !Runtime.dirty && !Runtime.busy
                                onClicked: Runtime.applyUpdate()
                            }

                            ArkButton {
                                text: "打开组件目录"
                                implicitHeight: 38
                                ghost: true
                                onClicked: AppControl.openDirectory(App.runtimeDir)
                            }

                            Item { Layout.fillWidth: true }

                            MicroLabel {
                                label: "FETCH + MERGE --FF-ONLY / NO RESET"
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 0.8
                            }
                        }
                    }
                }

                // 白名单诊断命令
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: commandsColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: commandsColumn
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "04"
                            english: "COMMANDS"
                            title: "诊断命令（白名单）"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "只允许执行下列经过验证的只读命令，执行结果会作为任务出现在「任务」页。"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: Adapter.diagnosticActions

                                delegate: ArkButton {
                                    text: modelData.title
                                    implicitHeight: 36
                                    enabled: Runtime.ready
                                    onClicked: page.runAction(modelData.id)
                                }
                            }
                        }

                        Repeater {
                            model: Adapter.diagnosticActions

                            delegate: MicroLabel {
                                Layout.fillWidth: true
                                label: modelData.id + " — " + modelData.description
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 0.5
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // 导出
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: exportColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: exportColumn
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "05"
                            english: "EXPORT"
                            title: "导出诊断包"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "导出为目录：summary、环境检测原始输出、初始化记录、任务历史与日志尾部。"
                                  + "疑似 token/password/secret 字段会被替换为 ***；不会包含游戏与 Hyps 组件文件。"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            PathField {
                                Layout.fillWidth: true
                                value: page.exportDir
                                mode: "dir"
                                dialogTitle: "选择诊断包导出目录"
                                onCommitted: function (path) { page.exportDir = path }
                            }

                            ArkButton {
                                text: "导出诊断包"
                                implicitHeight: 40
                                primary: true
                                onClicked: page.exportBundle()
                            }

                            ArkButton {
                                text: "打开上次导出"
                                implicitHeight: 40
                                ghost: true
                                enabled: Diag.lastExportPath.length > 0
                                onClicked: AppControl.openDirectory(Diag.lastExportPath)
                            }
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "上次导出"
                            value: Diag.lastExportPath.length > 0 ? Diag.lastExportPath
                                                                  : "尚未导出"
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: Diag.lastExportError.length > 0
                            text: Diag.lastExportError
                            color: Theme.colors.danger
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }
        }
    }
}
