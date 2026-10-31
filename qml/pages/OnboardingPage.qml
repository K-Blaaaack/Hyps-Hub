import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 首次初始化引导：依赖检查 → 安装组件 → 实时日志。 */
Item {
    id: page

    property var host

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight + Md3.space.xxl * 2
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MdScrollBar { }

        ColumnLayout {
            id: content
            width: Math.min(760, page.width - Md3.space.xl * 2)
            x: Math.max(Md3.space.xl, (page.width - width) / 2)
            y: Md3.space.xxl
            spacing: Md3.space.xl

            // 品牌
            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                spacing: Md3.space.md

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Md3.space.md

                    // 同上：引导页背景就是 surface，底板会隐形
                    MdBrandMark {
                        markSize: 38
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 2
                        MdText { role: "headlineMedium"; text: "Hyps Hub" }
                        MdText {
                            role: "bodyMedium"
                            tone: "variant"
                            text: "首次启动需要初始化上游组件"
                        }
                    }
                }

                MdText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    role: "bodyMedium"
                    tone: "variant"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Hyps CLI 会被克隆到独立目录，与系统包互不影响。初始化只需要网络与 Git。"
                }
            }

            // 01 环境检查
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "01 环境检查"
                        caption: Runtime.networkStatus === "ok" ? "网络可用" : Runtime.networkDetail

                        MdButton {
                            text: "重新检测"
                            variant: "text"
                            onClicked: {
                                Runtime.refreshPrerequisites();
                                Runtime.checkNetwork();
                            }
                        }
                    }

                    Repeater {
                        model: Runtime.prerequisites

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Md3.space.sm

                            MdIcon {
                                name: modelData.ok ? "check-circle" : "error"
                                size: 18
                                color: modelData.ok ? Theme.colors.success : Theme.colors.error
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100000
                                spacing: 0

                                MdText {
                                    role: "bodyMedium"
                                    text: modelData.name
                                }

                                MdText {
                                    Layout.fillWidth: true
                                    role: "bodySmall"
                                    tone: "variant"
                                    text: modelData.detail
                                    elide: Text.ElideMiddle
                                }

                                MdText {
                                    Layout.fillWidth: true
                                    visible: !modelData.ok && modelData.hint.length > 0
                                    role: "bodySmall"
                                    color: Theme.colors.warning
                                    text: "修复建议：" + modelData.hint
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            // 02 安装组件
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.md

                    MdSectionHeader {
                        title: "02 安装组件"
                        caption: "克隆完成后会自动校验目录结构"
                    }

                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "安装位置"
                        value: App.runtimeDir
                        mono: true
                        copyable: true
                        onCopyRequested: AppControl.copyToClipboard(App.runtimeDir)
                    }

                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "上游仓库"
                        value: Runtime.repositoryUrl
                        mono: true
                    }

                    MdProgressLinear {
                        Layout.fillWidth: true
                        visible: Runtime.busy
                        value: Runtime.progress >= 0 && Runtime.progress <= 1 ? Runtime.progress : -1
                    }

                    MdText {
                        Layout.fillWidth: true
                        visible: Runtime.busy || Runtime.progressText.length > 0
                        role: "bodySmall"
                        tone: "variant"
                        text: Runtime.progressText
                        elide: Text.ElideRight
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
                            text: Runtime.busy ? "初始化中…" : "开始初始化"
                            variant: "filled"
                            iconName: "download"
                            enabled: !Runtime.busy
                            onClicked: Runtime.startClone()
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
                }
            }

            // 03 实时日志
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "03 实时日志"
                        caption: Runtime.logLines.length + " 行"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        radius: Md3.shape.small
                        color: Theme.colors.codeSurface
                        border.width: 1
                        border.color: Theme.colors.outlineVariant
                        clip: true

                        ListView {
                            id: logView
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            model: Runtime.logLines
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: MdScrollBar { }

                            onCountChanged: Qt.callLater(function () { logView.positionViewAtEnd() })

                            delegate: MdText {
                                width: logView.width
                                role: "bodySmall"
                                mono: true
                                text: modelData
                                wrapMode: Text.WrapAnywhere
                            }
                        }

                        MdText {
                            anchors.centerIn: parent
                            visible: Runtime.logLines.length === 0
                            role: "bodySmall"
                            tone: "variant"
                            text: Runtime.busy ? "等待输出…" : "还没有日志，点击「开始初始化」"
                        }
                    }
                }
            }
        }
    }
}
