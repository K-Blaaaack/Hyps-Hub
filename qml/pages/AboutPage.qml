import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 独立关于页：版本、构建、系统、组件、许可与数据位置 */
Item {
    id: page

    property var host

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
                    index: "07"
                    title: "关于"
                    english: "ABOUT"
                    subtitle: "HYPS HUB / BUILD / LICENSES / PRIVACY"

                    ArkButton {
                        text: "上游项目"
                        implicitHeight: 40
                        onClicked: AppControl.openExternalUrl("https://github.com/MoYingJi/Hyps")
                    }

                    ArkButton {
                        text: "诊断"
                        implicitHeight: 40
                        ghost: true
                        onClicked: page.host.navigate("diagnostics")
                    }
                }

                // 品牌与简介
                ChamferedPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 246
                    contentMargin: 24
                    cut: 12

                    RowLayout {
                        anchors.fill: parent
                        spacing: 26

                        Image {
                            source: "qrc:/assets/hyps-hub.svg"
                            sourceSize.width: 132
                            sourceSize.height: 132
                            Layout.preferredWidth: 132
                            Layout.preferredHeight: 132
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            MicroLabel {
                                label: "APPLICATION // LOCAL CLIENT"
                                color: Theme.colors.signal
                                microSize: 10
                                tracking: 1.8
                            }

                            Text {
                                text: "HYPS HUB"
                                color: Theme.colors.paper
                                font.family: App.displayFontFamily
                                font.pixelSize: 44
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                                lineHeight: 0.95
                            }

                            RowLayout {
                                spacing: 10

                                ArkTag {
                                    text: "v" + App.appVersion
                                    kind: "signal"
                                    implicitHeight: 22
                                }

                                MicroLabel {
                                    label: "BUILD " + App.gitCommit
                                    color: Theme.colors.muted
                                    microSize: 9
                                    tracking: 1.0
                                }

                                MicroLabel {
                                    label: App.wayland ? "WAYLAND" : "X11"
                                    color: Theme.colors.disabled
                                    microSize: 9
                                    tracking: 1.0
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                text: "Hyps CLI 的独立图形客户端。通过适配层调用本机独立的 Hyps 组件。"
                                color: Theme.colors.paper2
                                font.family: App.uiFontFamily
                                font.pixelSize: 12
                                lineHeight: 1.45
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                spacing: 8

                                ArkButton {
                                    text: "打开上游项目"
                                    implicitHeight: 36
                                    ghost: true
                                    onClicked: AppControl.openExternalUrl("https://github.com/MoYingJi/Hyps")
                                }

                                ArkButton {
                                    text: "GPL-3.0 许可证"
                                    implicitHeight: 36
                                    ghost: true
                                    onClicked: AppControl.openExternalUrl("https://www.gnu.org/licenses/gpl-3.0.html")
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 230
                            spacing: 6

                            MicroLabel {
                                label: "RUNTIME TARGET"
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 1.2
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "组件"
                                value: Runtime.ready ? Runtime.commitShort : "未就绪"
                                valueColor: Runtime.ready ? Theme.colors.paper2 : Theme.colors.warn
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "分支"
                                value: Runtime.ready ? Runtime.branch : "—"
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "作者"
                                value: "K-Black"
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "工作区"
                                value: Runtime.ready ? (Runtime.dirty ? "有修改" : "干净") : "—"
                                valueColor: Runtime.dirty ? Theme.colors.warn : Theme.colors.paper2
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: page.width > 1120 ? 2 : 1
                    columnSpacing: 12
                    rowSpacing: 12

                    // 版本与系统
                    ChamferedPanel {
                        Layout.fillWidth: true
                        implicitHeight: versionColumn.implicitHeight + 36
                        contentMargin: 18
                        cut: 10

                        ColumnLayout {
                            id: versionColumn
                            anchors.fill: parent
                            spacing: 6

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "01"
                                english: "BUILD"
                                title: "版本与系统"
                            }

                            InfoRow { Layout.fillWidth: true; label: "应用版本"; value: "v" + App.appVersion }
                            InfoRow { Layout.fillWidth: true; label: "作者 / 维护"; value: "K-Black" }
                            InfoRow { Layout.fillWidth: true; label: "构建提交"; value: App.gitCommit }
                            InfoRow { Layout.fillWidth: true; label: "Qt"; value: App.qtVersion }
                            InfoRow { Layout.fillWidth: true; label: "系统"; value: App.osPrettyName }
                            InfoRow { Layout.fillWidth: true; label: "内核"; value: App.kernelVersion }
                            InfoRow {
                                Layout.fillWidth: true
                                label: "会话"
                                value: App.sessionType
                                       + (App.desktopName.length > 0 ? " / " + App.desktopName : "")
                                       + (App.runningAsRoot ? " · root" : "")
                                valueColor: App.runningAsRoot ? Theme.colors.danger : Theme.colors.paper2
                            }
                        }
                    }

                    // Hyps 组件
                    ChamferedPanel {
                        Layout.fillWidth: true
                        implicitHeight: componentColumn.implicitHeight + 36
                        contentMargin: 18
                        cut: 10

                        ColumnLayout {
                            id: componentColumn
                            anchors.fill: parent
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SectionHeader {
                                    Layout.fillWidth: true
                                    index: "02"
                                    english: "COMPONENT"
                                    title: "Hyps 组件"
                                }

                                ArkTag {
                                    text: Runtime.ready ? "READY" : "OFFLINE"
                                    kind: Runtime.ready ? "state" : "danger"
                                    implicitHeight: 20
                                }
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "提交"
                                value: Runtime.ready
                                       ? Runtime.commitShort + "  " + Runtime.commitSubject : "—"
                                wrap: true
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "组件目录"
                                value: App.runtimeDir
                                wrap: true
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "CLI 入口"
                                value: App.cliEntryPoint
                                wrap: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 8

                                ArkButton {
                                    text: "打开组件目录"
                                    implicitHeight: 34
                                    ghost: true
                                    onClicked: AppControl.openDirectory(App.runtimeDir)
                                }

                                ArkButton {
                                    text: "检查更新"
                                    implicitHeight: 34
                                    ghost: true
                                    enabled: Runtime.ready && !Runtime.busy
                                    onClicked: {
                                        Runtime.checkForUpdates();
                                        page.host.navigate("diagnostics");
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    // 许可与声明
                    ChamferedPanel {
                        Layout.fillWidth: true
                        implicitHeight: licenseColumn.implicitHeight + 36
                        contentMargin: 18
                        cut: 10

                        ColumnLayout {
                            id: licenseColumn
                            anchors.fill: parent
                            spacing: 8

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "03"
                                english: "LICENSES"
                                title: "许可与声明"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Hyps Hub 以 GPL-3.0-only 发布。上游 Hyps 亦为 GPL-3.0-only；"
                                      + "本项目不包含其源码，运行时由你本机上的独立 Hyps 组件提供。"
                                color: Theme.colors.paper2
                                font.family: App.uiFontFamily
                                font.pixelSize: 11
                                lineHeight: 1.45
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "作者 / 维护：K-Black（GitHub: K-Blaaaack）。"
                                color: Theme.colors.paper2
                                font.family: App.uiFontFamily
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "界面遵循用户提供的 Ark 设计规范，仅采用设计语言（近黑墨底、单一青色信号、"
                                      + "0 圆角、45° 切角、索引与双纹理）。不包含任何鹰角专有资产；"
                                      + "图形为原创几何标记、自生成纹理与自绘线性图标，字体仅使用系统本地回退。"
                                color: Theme.colors.muted
                                font.family: App.uiFontFamily
                                font.pixelSize: 11
                                lineHeight: 1.45
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                spacing: 8

                                ArkButton {
                                    text: "查看许可证全文"
                                    implicitHeight: 34
                                    ghost: true
                                    onClicked: AppControl.openExternalUrl("https://www.gnu.org/licenses/gpl-3.0.html")
                                }

                                ArkButton {
                                    text: "维护者 GitHub"
                                    implicitHeight: 34
                                    ghost: true
                                    onClicked: AppControl.openExternalUrl("https://github.com/K-Blaaaack")
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    // 数据与隐私
                    ChamferedPanel {
                        Layout.fillWidth: true
                        implicitHeight: dataColumn.implicitHeight + 36
                        contentMargin: 18
                        cut: 10

                        ColumnLayout {
                            id: dataColumn
                            anchors.fill: parent
                            spacing: 6

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "04"
                                english: "DATA"
                                title: "数据与隐私"
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "GUI 配置"
                                value: App.configDir
                                wrap: true
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "数据目录"
                                value: App.dataDir
                                wrap: true
                            }

                            InfoRow {
                                Layout.fillWidth: true
                                label: "状态目录"
                                value: App.stateDir
                                wrap: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "卸载程序不会删除组件、配置与日志；诊断导出会对疑似密钥字段脱敏。"
                                color: Theme.colors.muted
                                font.family: App.uiFontFamily
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                spacing: 8

                                ArkButton {
                                    text: "打开数据目录"
                                    implicitHeight: 34
                                    ghost: true
                                    onClicked: AppControl.openDirectory(App.dataDir)
                                }

                                ArkButton {
                                    text: "打开日志目录"
                                    implicitHeight: 34
                                    ghost: true
                                    onClicked: AppControl.openDirectory(App.logsDir)
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 6
                        height: 6
                        color: Theme.colors.signal
                    }

                    MicroLabel {
                        label: "HYPS HUB // " + App.osPrettyName + " // " + App.gitCommit
                        color: Theme.colors.disabled
                        microSize: 8
                        tracking: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    MicroLabel {
                        label: "AUTHOR K-BLACK · GPL-3.0-ONLY"
                        color: Theme.colors.muted
                        microSize: 8
                        tracking: 1.2
                    }
                }

                Item { Layout.preferredHeight: 8 }
            }
        }
    }
}
