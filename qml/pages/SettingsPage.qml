import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 设置：外观、通知、高级模式、运行环境、关于与隐私 */
Item {
    id: page

    property var host

    readonly property var themeChoices: [
        { key: "system", label: "跟随系统" },
        { key: "light", label: "浅色" },
        { key: "dark", label: "深色" }
    ]

    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Item {
            width: scroll.availableWidth
            height: content.implicitHeight + 44

            ColumnLayout {
                id: content
                x: 24
                y: 20
                width: parent.width - 48
                spacing: 14

                PageHeader {
                    Layout.fillWidth: true
                    index: "06"
                    title: "设置"
                    english: "SETTINGS"
                    subtitle: "APPEARANCE / ENVIRONMENT / PRIVACY"

                    ArkButton {
                        text: "关于 Hyps Hub"
                        implicitHeight: 40
                        ghost: true
                        onClicked: page.host.navigate("about")
                    }

                    ArkButton {
                        text: "打开配置目录"
                        implicitHeight: 40
                        ghost: true
                        onClicked: AppControl.openDirectory(App.configDir)
                    }
                }

                // 外观
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: appearanceColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: appearanceColumn
                        anchors.fill: parent
                        spacing: 10

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "01"
                            english: "APPEARANCE"
                            title: "外观"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "默认跟随系统 color-scheme。深色模式使用方舟设计的近黑墨底、纸阶文字与单一青色信号；"
                                  + "浅色模式保持同一套零圆角与切角几何，只反转墨/纸阶。"
                            color: Theme.colors.muted
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: 8

                            Repeater {
                                model: page.themeChoices

                                delegate: ArkButton {
                                    text: modelData.label
                                    implicitHeight: 38
                                    primary: Theme.preference === modelData.key
                                    ghost: Theme.preference !== modelData.key
                                    onClicked: Theme.preference = modelData.key
                                }
                            }

                            Item { Layout.fillWidth: true }

                            MicroLabel {
                                label: Theme.dark ? "DARK / ARK TOKENS" : "LIGHT / ARK TOKENS"
                                color: Theme.colors.signal
                                microSize: 9
                                tracking: 1.2
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle { width: 28; height: 12; color: Theme.colors.ink }
                            Rectangle { width: 28; height: 12; color: Theme.colors.ink2 }
                            Rectangle { width: 28; height: 12; color: Theme.colors.ink3 }
                            Rectangle { width: 28; height: 12; color: Theme.colors.line }
                            Rectangle { width: 28; height: 12; color: Theme.colors.signal }
                            Rectangle { width: 28; height: 12; color: Theme.colors.state }
                            Rectangle { width: 28; height: 12; color: Theme.colors.warn }
                            Rectangle { width: 28; height: 12; color: Theme.colors.danger }
                            MicroLabel {
                                label: "INK / LINE / SIGNAL / STATE / WARN / DANGER"
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 0.8
                            }
                        }
                    }
                }

                // 通知与行为
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: behaviorColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: behaviorColumn
                        anchors.fill: parent
                        spacing: 10

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "02"
                            english: "BEHAVIOR"
                            title: "通知与行为"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "桌面通知"
                                    color: Theme.colors.paper2
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 13
                                }

                                MicroLabel {
                                    label: Notifier.available
                                           ? "D-BUS org.freedesktop.Notifications 可用；仅窗口不在前台时提示任务结束"
                                           : "当前会话没有可用的通知服务，将静默跳过"
                                    color: Notifier.available ? Theme.colors.muted
                                                              : Theme.colors.warn
                                    microSize: 9
                                    tracking: 0.6
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.notificationsEnabled
                                onToggled: function (value) {
                                    Settings.notificationsEnabled = value;
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colors.rule }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "高级模式"
                                    color: Theme.colors.paper2
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 13
                                }

                                MicroLabel {
                                    label: "在配置页展开环境变量与原始编辑器；默认折叠，避免普通用户面对大量参数"
                                    color: Theme.colors.muted
                                    microSize: 9
                                    tracking: 0.6
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.advancedMode
                                onToggled: function (value) {
                                    Settings.advancedMode = value;
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colors.rule }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "窗口状态"
                                    color: Theme.colors.paper2
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 13
                                }

                                MicroLabel {
                                    label: "退出时保存窗口大小与最大化状态；Wayland 下窗口位置由合成器决定"
                                    color: Theme.colors.muted
                                    microSize: 9
                                    tracking: 0.6
                                }
                            }

                            MicroLabel {
                                label: page.host.width + " × " + page.host.height
                                color: Theme.colors.disabled
                                microSize: 9
                                tracking: 0.8
                            }
                        }
                    }
                }

                // 运行环境
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: runtimeColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10

                    ColumnLayout {
                        id: runtimeColumn
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "03"
                            english: "COMPONENT"
                            title: "Hyps 组件"
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "Hyps 组件"
                            value: App.runtimeDir
                            wrap: true
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "提交"
                            value: Runtime.ready
                                   ? Runtime.commitShort + "  " + Runtime.commitSubject : "尚未就绪"
                            wrap: true
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "CLI 入口"
                            value: App.cliEntryPoint
                            wrap: true
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "上游仓库"
                            value: "https://github.com/MoYingJi/Hyps"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ArkButton {
                                text: "打开组件目录"
                                implicitHeight: 36
                                ghost: true
                                onClicked: AppControl.openDirectory(App.runtimeDir)
                            }

                            ArkButton {
                                text: "检查更新"
                                implicitHeight: 36
                                ghost: true
                                enabled: Runtime.ready && !Runtime.busy
                                onClicked: {
                                    Runtime.checkForUpdates();
                                    page.host.navigate("diagnostics");
                                }
                            }

                            ArkButton {
                                text: "查看环境诊断"
                                implicitHeight: 36
                                ghost: true
                                onClicked: page.host.navigate("diagnostics")
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // 隐私与退出
                ChamferedPanel {
                    Layout.fillWidth: true
                    implicitHeight: privacyColumn.implicitHeight + 36
                    contentMargin: 18
                    cut: 10
                    accentColor: Theme.colors.danger

                    ColumnLayout {
                        id: privacyColumn
                        anchors.fill: parent
                        spacing: 8

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "04"
                            english: "PRIVACY"
                            title: "数据与退出"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "GUI 配置位于 " + App.configDir + "，Hyps CLI 配置位于 "
                                  + App.hypsConfigDir + "。卸载应用不会删除 Hyps 组件、配置与日志；"
                                  + "如需彻底清理请手动删除 XDG 目录。"
                            color: Theme.colors.paper2
                            font.family: App.uiFontFamily
                            font.pixelSize: 11
                            lineHeight: 1.45
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: 8

                            ArkButton {
                                text: "打开数据目录"
                                implicitHeight: 36
                                ghost: true
                                onClicked: AppControl.openDirectory(App.dataDir)
                            }

                            ArkButton {
                                text: "打开日志目录"
                                implicitHeight: 36
                                ghost: true
                                onClicked: AppControl.openDirectory(App.logsDir)
                            }

                            Item { Layout.fillWidth: true }

                            ArkButton {
                                text: "退出 Hyps Hub"
                                implicitHeight: 36
                                danger: true
                                onClicked: {
                                    if (Tasks.activeCount > 0) {
                                        page.host.confirmQuit();
                                    } else {
                                        AppControl.quitApplication();
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }
        }
    }
}
