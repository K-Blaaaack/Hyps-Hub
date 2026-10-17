import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 首页：占满窗口的仪表盘，状态全部来自真实检测，不虚构遥测 */
Item {
    id: page

    property var host

    function collectWarnings() {
        const result = [];
        const groups = EnvReport.groups;
        for (let i = 0; i < groups.length; ++i) {
            const items = groups[i].items;
            for (let j = 0; j < items.length; ++j) {
                if (items[j].status === "warn" || items[j].status === "fail") {
                    result.push(items[j]);
                }
            }
        }
        return result;
    }

    function stateKind() {
        if (Runtime.state === "ready") {
            return "state";
        }
        return Runtime.state === "error" || Runtime.state === "invalid" ? "danger" : "warn";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        PageHeader {
            Layout.fillWidth: true
            index: "01"
            title: "首页"
            english: "OVERVIEW"
            subtitle: "SYSTEM STATUS / LOCAL RUNTIME"

            ArkButton {
                text: "重新检测"
                implicitHeight: 40
                enabled: Runtime.ready
                onClicked: Adapter.checkEnvironment()
            }

            ArkButton {
                text: "诊断"
                implicitHeight: 40
                ghost: true
                onClicked: page.host.navigate("diagnostics")
            }
        }

        ChamferedPanel {
            Layout.fillWidth: true
            visible: App.runningAsRoot || Adapter.lastError.length > 0
            implicitHeight: warningColumn.implicitHeight + 32
            contentMargin: 16
            cut: 8
            accentColor: Theme.colors.danger

            ColumnLayout {
                id: warningColumn
                anchors.fill: parent
                spacing: 5

                MicroLabel {
                    label: "ATTENTION"
                    color: Theme.colors.danger
                    microSize: 9
                    tracking: 1.6
                }

                Text {
                    Layout.fillWidth: true
                    visible: App.runningAsRoot
                    text: "当前以 root 运行。Hyps 会拒绝 root 启动游戏，请改用普通用户运行 Hyps Hub。"
                    color: Theme.colors.paper2
                    font.family: App.uiFontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    visible: Adapter.lastError.length > 0
                    text: Adapter.lastError
                    color: Theme.colors.danger
                    font.family: App.uiFontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: page.width > 1080 ? 4 : 2
            columnSpacing: 12
            rowSpacing: 12

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                english: "APPLICATION"
                label: "Hyps Hub 版本"
                value: "v" + App.appVersion
                sub: App.gitCommit.length > 0 ? App.gitCommit : "local build"
                statusText: App.wayland ? "WAYLAND" : "X11"
                statusKind: "neutral"
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                english: "RUNTIME"
                label: "Hyps 运行副本"
                value: Runtime.ready ? (Runtime.commitShort.length > 0 ? Runtime.commitShort : "READY")
                                     : "—"
                sub: Runtime.ready ? (Runtime.branch + " · " + Runtime.commitSubject)
                                   : Runtime.state
                statusText: Runtime.ready ? "READY" : Runtime.state.toUpperCase()
                statusKind: page.stateKind()
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                english: "CLI"
                label: "Hyps CLI"
                value: Runtime.ready ? (Adapter.canRun ? "可用" : "不可用") : "—"
                sub: App.cliEntryPoint
                statusText: Adapter.cliVerified ? "VERIFIED" : "UNVERIFIED"
                statusKind: Adapter.cliVerified ? "state" : "warn"
            }

            StatCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                english: "DEPENDENCIES"
                label: "必需项通过"
                value: EnvReport.hasReport
                       ? EnvReport.requiredPassed + "/" + EnvReport.requiredTotal : "—"
                sub: EnvReport.hasReport ? EnvReport.checkedAtText : "尚未检测"
                statusText: EnvReport.hasReport
                            ? (EnvReport.requiredFailed > 0
                               ? "MISSING " + EnvReport.requiredFailed : "OK")
                            : "—"
                statusKind: EnvReport.hasReport
                            ? (EnvReport.requiredFailed > 0 ? "danger" : "state") : "neutral"
            }
        }

        // 主操作区：占满剩余高度
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            ChamferedPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 520
                contentMargin: 18
                cut: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    SectionHeader {
                        Layout.fillWidth: true
                        index: "02"
                        english: "ENVIRONMENT"
                        title: "环境检测"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        MicroLabel {
                            label: EnvReport.hasReport ? EnvReport.summaryText : "尚未检测"
                            color: Theme.colors.paper2
                            microSize: 10
                            tracking: 0.6
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        ArkTag {
                            text: EnvReport.warnings > 0 ? "WARN " + EnvReport.warnings : "CLEAN"
                            kind: EnvReport.warnings > 0 ? "warn" : "state"
                            implicitHeight: 22
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.colors.rule
                    }

                    ScrollView {
                        id: envScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: envScroll.availableWidth
                            spacing: 5

                            Repeater {
                                model: EnvReport.groups

                                delegate: ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
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
                                                                                       : Theme.colors.disabled))
                                            }

                                            Text {
                                                Layout.preferredWidth: 150
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

                            Text {
                                Layout.fillWidth: true
                                visible: !EnvReport.hasReport
                                text: "尚未运行环境检测。点击下方「重新检测」执行上游 init.sh --check。"
                                color: Theme.colors.muted
                                font.family: App.uiFontFamily
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ArkButton {
                            text: "重新检测"
                            implicitHeight: 40
                            enabled: Runtime.ready
                            onClicked: Adapter.checkEnvironment()
                        }

                        ArkButton {
                            text: "查看完整报表"
                            implicitHeight: 40
                            ghost: true
                            onClicked: page.host.navigate("diagnostics")
                        }

                        Item { Layout.fillWidth: true }

                        MicroLabel {
                            label: EnvReport.checkedAtText
                            color: Theme.colors.disabled
                            microSize: 9
                            tracking: 0.8
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(380, page.width * 0.34)
                Layout.maximumWidth: 520
                spacing: 12

                ChamferedPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 300
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "03"
                            english: "RECENT TASKS"
                            title: "最近任务"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: Tasks.recentTasks
                            spacing: 0

                            delegate: Item {
                                width: ListView.view.width
                                height: 50

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 10

                                    Rectangle {
                                        width: 7
                                        height: 7
                                        color: modelData.state === "succeeded" ? Theme.colors.state
                                             : (modelData.state === "failed" ? Theme.colors.danger
                                                : (modelData.state === "running" ? Theme.colors.signal
                                                                                 : Theme.colors.warn))
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.label
                                            color: Theme.colors.paper2
                                            font.family: App.uiFontFamily
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        MicroLabel {
                                            label: modelData.stateText + " · " + modelData.durationText
                                            color: Theme.colors.muted
                                            microSize: 9
                                            tracking: 0.6
                                        }
                                    }

                                    ArkTag {
                                        text: modelData.stateText
                                        kind: modelData.state === "succeeded" ? "state"
                                             : (modelData.state === "failed" ? "danger" : "warn")
                                        implicitHeight: 20
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 1
                                    color: Theme.colors.rule
                                    opacity: 0.6
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Tasks.select(modelData.id);
                                        page.host.navigate("tasks");
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: Tasks.recentTasks.length === 0
                            text: "还没有任务记录。启动游戏或运行环境检测后会出现在这里。"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        ArkButton {
                            text: "全部任务"
                            implicitHeight: 40
                            ghost: true
                            onClicked: page.host.navigate("tasks")
                        }
                    }
                }

                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: runtimeInfo.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: runtimeInfo
                        anchors.fill: parent
                        spacing: 6

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "04"
                            english: "RUNTIME"
                            title: "运行副本"
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "提交"
                            value: Runtime.ready
                                   ? Runtime.commitShort + "  " + Runtime.commitSubject : "—"
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "工作区"
                            value: Runtime.ready
                                   ? (Runtime.dirty ? "有未提交修改" : "干净")
                                   : Runtime.state
                            valueColor: Runtime.dirty ? Theme.colors.warn : Theme.colors.paper2
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "CLI"
                            value: App.cliEntryPoint
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 8

                            ArkButton {
                                text: "打开运行目录"
                                implicitHeight: 38
                                ghost: true
                                onClicked: AppControl.openDirectory(App.runtimeDir)
                            }

                            ArkButton {
                                text: "更新"
                                implicitHeight: 38
                                ghost: true
                                onClicked: page.host.navigate("diagnostics")
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        ChamferedPanel {
            Layout.fillWidth: true
            implicitHeight: 92
            contentMargin: 16
            cut: 10

            RowLayout {
                anchors.fill: parent
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    MicroLabel {
                        label: "QUICK ACTIONS"
                        color: Theme.colors.signal
                        microSize: 9
                        tracking: 1.6
                    }

                    Text {
                        text: "选择游戏并发起一次真实启动，或检查运行环境。"
                        color: Theme.colors.muted
                        font.family: App.uiFontFamily
                        font.pixelSize: 11
                    }
                }

                ArkButton {
                    text: "打开游戏"
                    primary: true
                    implicitHeight: 42
                    onClicked: page.host.navigate("games")
                }

                ArkButton {
                    text: "通用配置"
                    implicitHeight: 42
                    ghost: true
                    onClicked: page.host.navigate("config")
                }

                ArkButton {
                    text: "环境更新"
                    implicitHeight: 42
                    ghost: true
                    onClicked: page.host.navigate("diagnostics")
                }
            }
        }
    }
}
