import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 关于页：版本、构建信息、上游组件、数据隔离说明、命令速查。 */
Item {
    id: page

    property var host

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

            // 品牌头
            MdCard {
                Layout.fillWidth: true
                padding: Md3.space.xl

                RowLayout {
                    anchors.fill: parent
                    spacing: Md3.space.lg

                    // 不要底板：卡片是 filled（surfaceContainerHighest），
                    // 底板无论取 surface 还是 primaryContainer，都会在某处与背景同色而隐形。
                    // 标识本身已按主题配色，直接压在卡片上对比度就够。
                    MdBrandMark {
                        markSize: 44
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.xs

                        RowLayout {
                            spacing: Md3.space.sm
                            MdText {
                                role: "headlineSmall"
                                text: "Hyps Hub"
                            }
                            MdTag {
                                text: "v" + App.appVersion
                                status: "primary"
                            }
                            MdTag {
                                visible: App.gitCommit.length > 0
                                text: App.gitCommit.substring(0, 7)
                                status: "neutral"
                            }
                        }

                        MdText {
                            Layout.fillWidth: true
                            role: "bodyMedium"
                            tone: "variant"
                            text: "Hyps CLI 的原生 Linux 桌面客户端：管理游戏配置、运行器、任务与日志，全部数据留在本机。"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // 构建信息
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader { title: "构建信息" }

                    MdInfoRow { label: "应用版本"; value: App.appVersion; mono: true }
                    MdInfoRow { label: "构建提交"; value: App.gitCommit.length > 0 ? App.gitCommit : "—"; mono: true; copyable: true }
                    MdInfoRow { label: "Qt 版本"; value: App.qtVersion; mono: true }
                    MdInfoRow { label: "内核版本"; value: App.kernelVersion; mono: true; copyable: true }
                    MdInfoRow { label: "发行版"; value: App.osPrettyName }
                    MdInfoRow { label: "会话类型"; value: App.sessionType + (App.wayland ? "（Wayland）" : "（X11）") }
                    MdInfoRow { label: "桌面环境"; value: App.desktopName.length > 0 ? App.desktopName : "—" }
                    MdInfoRow { label: "运行身份"; value: App.runningAsRoot ? "root" : "普通用户" }
                    MdInfoRow { label: "界面字体"; value: App.uiFontFamily; mono: true }
                    MdInfoRow { label: "等宽字体"; value: App.monoFontFamily; mono: true }
                }
            }

            // 上游组件
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "上游组件"
                        caption: "Hyps CLI 的独立克隆，与系统包互不影响"
                        MdTag {
                            text: Runtime.branch.length > 0 ? Runtime.branch : "—"
                            status: "neutral"
                        }
                    }

                    MdInfoRow {
                        label: "提交"
                        value: Runtime.commitShort.length > 0
                               ? Runtime.commitShort + "  " + Runtime.commitSubject
                               : "尚未初始化"
                        mono: true
                    }
                    MdInfoRow {
                        label: "工作区"
                        value: Runtime.dirty ? "有未提交改动" : "干净"
                    }
                    MdInfoRow {
                        label: "组件目录"
                        value: Runtime.runtimePath
                        mono: true
                        copyable: true
                        onCopyRequested: AppControl.copyToClipboard(Runtime.runtimePath)
                    }
                    MdInfoRow {
                        label: "CLI 入口"
                        value: App.cliEntryPoint
                        mono: true
                        copyable: true
                        onCopyRequested: AppControl.copyToClipboard(App.cliEntryPoint)
                    }
                    MdInfoRow {
                        label: "CLI 自检"
                        value: Adapter.cliVerified ? "已通过" : "未验证"
                    }

                    RowLayout {
                        Layout.topMargin: Md3.space.sm
                        spacing: Md3.space.sm

                        MdButton {
                            text: "打开组件目录"
                            variant: "tonal"
                            iconName: "folder"
                            onClicked: AppControl.openDirectory(Runtime.runtimePath)
                        }
                        MdButton {
                            text: "上游仓库"
                            variant: "outlined"
                            iconName: "external"
                            onClicked: AppControl.openExternalUrl(Runtime.repositoryUrl)
                        }
                        MdButton {
                            text: "检查更新"
                            variant: "text"
                            iconName: "refresh"
                            onClicked: page.host ? page.host.navigate("diagnostics") : undefined
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 数据隔离
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "数据隔离"
                        caption: "三处目录互不干扰，删除 GUI 数据不会影响上游组件"
                    }

                    MdInfoRow { label: "数据目录"; value: App.dataDir; mono: true; copyable: true; onCopyRequested: AppControl.copyToClipboard(App.dataDir) }
                    MdInfoRow { label: "配置目录"; value: App.configDir; mono: true; copyable: true; onCopyRequested: AppControl.copyToClipboard(App.configDir) }
                    MdInfoRow { label: "组件目录"; value: App.runtimeRoot; mono: true; copyable: true; onCopyRequested: AppControl.copyToClipboard(App.runtimeRoot) }

                    MdText {
                        Layout.fillWidth: true
                        Layout.topMargin: Md3.space.xs
                        role: "bodySmall"
                        tone: "variant"
                        text: "游戏配置写入组件目录下的 config/；GUI 自身的窗口状态与偏好写入配置目录。"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // 常用命令
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader { title: "常用命令" }

                    MdCodeBlock {
                        Layout.fillWidth: true
                        maxHeight: 140
                        text: "hyps doctor\nhyps update\nhyps run --game arknights"
                    }

                    MdText {
                        Layout.fillWidth: true
                        role: "bodySmall"
                        tone: "variant"
                        text: "命令行与 GUI 共用同一份组件与配置，二者可以混用。"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // 许可
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader { title: "许可与致谢" }

                    MdInfoRow { label: "许可"; value: "GPL-3.0-only" }
                    MdInfoRow { label: "上游项目"; value: "Hyps（MoYingJi）" }
                    MdInfoRow { label: "界面规范"; value: "Material Design 3" }

                    MdText {
                        Layout.fillWidth: true
                        Layout.topMargin: Md3.space.xs
                        role: "bodySmall"
                        tone: "variant"
                        text: "© 2025 Hyps Hub contributors。本程序为自由软件，在 GPL-3.0-only 条款下分发，不提供任何担保。"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
