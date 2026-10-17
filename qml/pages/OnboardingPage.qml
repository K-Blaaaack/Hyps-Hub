import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 首次初始化向导：真实检测 → 异步克隆 → 初始化隔离配置，失败可安全重试 */
Item {
    id: page

    property var host
    property bool bootstrapStarted: false

    function bootstrap() {
        if (!Runtime.ready || bootstrapStarted) {
            return;
        }
        bootstrapStarted = true;
        if (!Configs.common.exists) {
            Adapter.initializeConfig();
        } else if (!EnvReport.hasReport) {
            Adapter.checkEnvironment();
        }
    }

    function stateLabel() {
        switch (Runtime.state) {
        case "missing": return "尚未初始化";
        case "verifying": return "正在检测运行副本";
        case "cloning": return "正在克隆上游仓库";
        case "ready": return "运行副本就绪";
        case "invalid": return "运行副本无效";
        case "updating": return "正在更新";
        case "error": return "初始化失败";
        default: return Runtime.state;
        }
    }

    function canClone() {
        return !Runtime.busy && (Runtime.state === "missing" || Runtime.state === "error");
    }

    Component.onCompleted: {
        if (Runtime.ready) {
            bootstrap();
        } else if (Runtime.networkStatus === "idle") {
            Runtime.checkNetwork();
        }
    }

    Connections {
        target: Runtime
        function onStateChanged() {
            if (Runtime.ready) {
                page.bootstrap();
            }
        }
    }

    Connections {
        target: Adapter
        function onConfigInitialized() {
            Adapter.checkEnvironment();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        // 顶部：品牌 + 首次运行标识
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Image {
                width: 40
                height: 40
                source: "qrc:/assets/hyps-hub.svg"
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: "HYPS HUB"
                    color: Theme.colors.paper
                    font.family: App.displayFontFamily
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.letterSpacing: 2.0
                }

                MicroLabel {
                    label: "FIRST RUN / RUNTIME BOOTSTRAP"
                    color: Theme.colors.signal
                    microSize: 9
                    tracking: 1.6
                }
            }

            Item { Layout.fillWidth: true }

            MicroLabel {
                label: "v" + App.appVersion
                color: Theme.colors.muted
                microSize: 9
                tracking: 1.2
            }

            ArkTag {
                text: stateLabel()
                kind: Runtime.ready ? "state" : (Runtime.state === "error" || Runtime.state === "invalid" ? "danger" : "signal")
                implicitHeight: 22
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.rule
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 28

            // 左侧舞台：大字 + 真实路径信息
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 260
                Layout.maximumWidth: 380
                Layout.preferredWidth: 360

                Column {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    spacing: 10

                    MicroLabel {
                        label: "PRTS // LOCAL CLIENT"
                        color: Theme.colors.signal
                        microSize: 10
                        tracking: 2.0
                    }

                    Text {
                        text: "HYPS"
                        color: Theme.colors.paper
                        font.family: App.displayFontFamily
                        font.pixelSize: Math.min(96, page.width * 0.085)
                        font.weight: Font.Bold
                        font.letterSpacing: -3.5
                        lineHeight: 0.82
                    }

                    Row {
                        spacing: 10

                        Text {
                            text: "HUB"
                            color: Theme.colors.signal
                            font.family: App.displayFontFamily
                            font.pixelSize: Math.min(96, page.width * 0.085)
                            font.weight: Font.Bold
                            font.letterSpacing: -3.5
                            lineHeight: 0.82
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            color: Theme.colors.state
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 14
                        }
                    }

                    StripeRuler {
                        width: 260
                        height: 8
                    }

                    Text {
                        width: Math.min(330, page.width * 0.3)
                        text: "首次运行会在你的 XDG 数据目录克隆一份独立的 Hyps 运行副本。"
                              + "它不会读取、修改或写入你现有的 ~/Hyps 工作区。"
                        color: Theme.colors.paper2
                        font.family: App.uiFontFamily
                        font.pixelSize: 13
                        lineHeight: 1.45
                        wrapMode: Text.WordWrap
                    }

                    InfoRow {
                        width: Math.min(350, page.width * 0.32)
                        label: "运行副本"
                        value: App.runtimeDir
                        wrap: true
                    }

                    InfoRow {
                        width: Math.min(350, page.width * 0.32)
                        label: "Hyps 配置"
                        value: App.hypsConfigDir
                        wrap: true
                    }
                }
            }

            // 右侧：步骤面板
            ChamferedPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 540
                cut: 12
                contentMargin: 22

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    SectionHeader {
                        Layout.fillWidth: true
                        index: "01"
                        english: "PREFLIGHT"
                        title: "前置检查"
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

                            Text {
                                text: modelData.name
                                color: Theme.colors.paper2
                                font.family: App.uiFontFamily
                                font.pixelSize: 12
                                Layout.preferredWidth: 86
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
                                label: modelData.ok ? "OK" : "NG"
                                color: modelData.ok ? Theme.colors.state : Theme.colors.danger
                                microSize: 8
                                tracking: 1.0
                            }
                        }
                    }

                    SectionHeader {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        index: "02"
                        english: "RUNTIME"
                        title: "克隆运行副本"
                    }

                    ArkProgress {
                        Layout.fillWidth: true
                        value: Runtime.progress
                        indeterminate: Runtime.state === "cloning" && Runtime.progress <= 0.001
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: Runtime.progressText.length > 0 ? Runtime.progressText : stateLabel()
                            color: Theme.colors.paper2
                            font.family: App.uiFontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        MicroLabel {
                            label: Math.round(Runtime.progress * 100) + "%"
                            color: Theme.colors.signal
                            microSize: 9
                            tracking: 1.0
                        }
                    }

                    MicroLabel {
                        Layout.fillWidth: true
                        label: App.runtimeDir
                        color: Theme.colors.disabled
                        microSize: 9
                        tracking: 0.6
                        elide: Text.ElideMiddle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ArkButton {
                            text: "检查网络"
                            implicitHeight: 40
                            enabled: !Runtime.busy
                            onClicked: Runtime.checkNetwork()
                        }

                        ArkButton {
                            visible: page.canClone()
                            text: Runtime.state === "error" ? "重试初始化" : "开始初始化"
                            implicitHeight: 40
                            primary: true
                            enabled: page.canClone() && Runtime.networkStatus !== "checking"
                            onClicked: Runtime.startClone()
                        }

                        ArkButton {
                            visible: Runtime.state === "cloning"
                            text: "取消克隆"
                            implicitHeight: 40
                            danger: true
                            onClicked: Runtime.cancelOperation()
                        }

                        ArkButton {
                            visible: Runtime.state === "invalid"
                            text: "重新检测"
                            implicitHeight: 40
                            onClicked: Runtime.refresh()
                        }

                        ArkButton {
                            visible: Runtime.ready && !Configs.common.exists
                            text: "初始化配置"
                            implicitHeight: 40
                            primary: true
                            onClicked: Adapter.initializeConfig()
                        }

                        ArkButton {
                            visible: Runtime.ready
                            text: "重新检测依赖"
                            implicitHeight: 40
                            ghost: true
                            onClicked: Adapter.checkEnvironment()
                        }

                        Item { Layout.fillWidth: true }

                        ArkButton {
                            text: "打开数据目录"
                            implicitHeight: 40
                            ghost: true
                            onClicked: AppControl.openDirectory(App.dataDir)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Runtime.networkDetail.length > 0
                        text: (Runtime.networkStatus === "ok" ? "网络：" : "网络：")
                              + Runtime.networkDetail
                        color: Runtime.networkStatus === "ok" ? Theme.colors.state
                             : (Runtime.networkStatus === "error" ? Theme.colors.danger
                                                                  : Theme.colors.muted)
                        font.family: App.uiFontFamily
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Runtime.errorMessage.length > 0
                        text: Runtime.errorMessage
                        color: Theme.colors.danger
                        font.family: App.uiFontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    SectionHeader {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        index: "03"
                        english: "CONFIGURATION"
                        title: "配置与依赖"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MicroLabel {
                            label: Configs.common.exists ? "CONFIG READY" : "CONFIG PENDING"
                            color: Configs.common.exists ? Theme.colors.state : Theme.colors.warn
                            microSize: 9
                            tracking: 1.2
                        }

                        MicroLabel {
                            label: EnvReport.hasReport ? EnvReport.summaryText : "尚未检测环境"
                            color: Theme.colors.muted
                            microSize: 9
                            tracking: 0.8
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        ArkTag {
                            visible: EnvReport.hasReport
                            text: EnvReport.requiredFailed > 0 ? "MISSING " + EnvReport.requiredFailed
                                                               : "READY"
                            kind: EnvReport.requiredFailed > 0 ? "danger" : "state"
                            implicitHeight: 20
                        }
                    }

                    // 实时操作日志
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 90
                        color: Theme.colors.codeBg
                        border.width: 1
                        border.color: Theme.colors.rule

                        ListView {
                            id: setupLog
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            model: Runtime.logLines
                            spacing: 1

                            delegate: Text {
                                width: setupLog.width
                                text: modelData
                                color: Theme.colors.paper2
                                font.family: App.monoFontFamily
                                font.pixelSize: 10
                                wrapMode: Text.WrapAnywhere
                            }

                            onCountChanged: Qt.callLater(setupLog.positionViewAtEnd)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: Runtime.logLines.length === 0
                            text: "等待初始化操作"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // 底部：隔离声明
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 6
                height: 6
                color: Runtime.ready ? Theme.colors.state : Theme.colors.warn
            }

            MicroLabel {
                label: "ISOLATION: GUI 仅调用 $XDG_DATA_HOME/hyps-hub/runtime/Hyps；不会写入 ~/Hyps"
                color: Theme.colors.muted
                microSize: 9
                tracking: 0.8
            }

            Item { Layout.fillWidth: true }

            MicroLabel {
                label: App.osPrettyName + " / " + App.sessionType
                color: Theme.colors.disabled
                microSize: 9
                tracking: 0.8
            }
        }
    }
}
