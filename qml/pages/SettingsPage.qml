import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 设置页：外观、通知、高级模式、目录、环境信息、窗口。 */
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

            MdBanner {
                Layout.fillWidth: true
                visible: Settings.loadWarning.length > 0
                status: "warning"
                text: Settings.loadWarning
            }

            MdBanner {
                Layout.fillWidth: true
                visible: App.runningAsRoot
                status: "warning"
                text: "当前以 root 身份运行。GUI 与游戏配置不需要 root 权限，建议用普通用户启动。"
            }

            // 外观
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.md

                    MdSectionHeader {
                        title: "外观"
                        caption: "MD3 基线配色，浅色/深色两套完整语义色"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.lg

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 100000
                            spacing: 2
                            MdText { role: "bodyLarge"; text: "主题" }
                            MdText {
                                role: "bodySmall"
                                tone: "variant"
                                text: "当前生效：" + (Theme.dark ? "深色" : "浅色")
                                      + (Theme.preference === "system"
                                         ? "（跟随系统" + (Theme.systemDark ? "，系统为深色" : "，系统为浅色") + "）"
                                         : "（手动指定）")
                            }
                        }

                        MdSegmentedButton {
                            model: [
                                { value: "system", text: "跟随系统" },
                                { value: "light", text: "浅色" },
                                { value: "dark", text: "深色" }
                            ]
                            currentValue: Theme.preference
                            onActivated: function (value) {
                                // preference 是 WRITE 属性，只能赋值，不能当方法调
                                Theme.preference = value;
                                Settings.theme = value;
                            }
                        }
                    }
                }
            }

            // 行为
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader { title: "行为" }

                    MdSwitchRow {
                        Layout.fillWidth: true
                        title: "任务完成通知"
                        description: "任务结束且窗口不在前台时发送系统通知"
                        checked: Settings.notificationsEnabled
                        onToggled: function (value) { Settings.notificationsEnabled = value }
                    }

                    MdDivider { Layout.fillWidth: true; inset: true }

                    MdSwitchRow {
                        Layout.fillWidth: true
                        title: "高级模式"
                        description: "在配置页显示原始编辑器、在诊断页显示诊断命令"
                        checked: Settings.advancedMode
                        onToggled: function (value) { Settings.advancedMode = value }
                    }
                }
            }

            // 目录
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.xs

                    MdSectionHeader {
                        title: "目录"
                        caption: "遵循 XDG 规范，可用环境变量覆盖"
                    }

                    Repeater {
                        model: [
                            { label: "数据目录", value: App.dataDir },
                            { label: "配置目录", value: App.configDir },
                            { label: "状态目录", value: App.stateDir },
                            { label: "缓存目录", value: App.cacheDir },
                            { label: "日志目录", value: App.logsDir },
                            { label: "任务日志", value: App.tasksLogDir },
                            { label: "组件根目录", value: App.runtimeRoot },
                            { label: "Hyps 配置", value: App.hypsConfigDir }
                        ]

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Md3.space.sm

                            MdInfoRow {
                                Layout.fillWidth: true
                                label: modelData.label
                                value: modelData.value
                                mono: true
                                copyable: true
                                onCopyRequested: AppControl.copyToClipboard(modelData.value)
                            }

                            MdIconButton {
                                iconName: "external"
                                size: 32
                                iconSize: 16
                                tooltip: "在文件管理器中打开"
                                onClicked: AppControl.openDirectory(modelData.value)
                            }
                        }
                    }
                }
            }

            // 环境
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.xs

                    MdSectionHeader { title: "运行环境" }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        columns: content.width > 720 ? 2 : 1
                        columnSpacing: Md3.space.xl
                        rowSpacing: 0

                        MdInfoRow { Layout.fillWidth: true; label: "界面字体"; value: App.uiFontFamily; mono: true }
                        MdInfoRow { Layout.fillWidth: true; label: "等宽字体"; value: App.monoFontFamily; mono: true }
                        MdInfoRow { Layout.fillWidth: true; label: "Qt"; value: App.qtVersion; mono: true }
                        MdInfoRow { Layout.fillWidth: true; label: "内核"; value: App.kernelVersion; mono: true }
                        MdInfoRow { Layout.fillWidth: true; label: "发行版"; value: App.osPrettyName }
                        MdInfoRow { Layout.fillWidth: true; label: "会话"; value: App.sessionType }
                        MdInfoRow { Layout.fillWidth: true; label: "桌面"; value: App.desktopName.length > 0 ? App.desktopName : "—" }
                        MdInfoRow { Layout.fillWidth: true; label: "Wayland"; value: App.wayland ? "是" : "否" }
                    }
                }
            }

            // 窗口
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader { title: "窗口" }

                    MdInfoRow {
                        Layout.fillWidth: true
                        label: "上次几何"
                        value: {
                            const g = Settings.windowGeometry();
                            if (!g || g.width === undefined) {
                                return "未记录";
                            }
                            return g.width + " × " + g.height + "  @ " + g.x + "," + g.y
                                   + (g.maximized ? "（最大化）" : "");
                        }
                        mono: true
                    }

                    RowLayout {
                        spacing: Md3.space.sm
                        MdButton {
                            text: "恢复默认尺寸"
                            variant: "tonal"
                            iconName: "refresh"
                            onClicked: {
                                Settings.saveWindowGeometry(80, 80, 1180, 760, false);
                                if (page.host) {
                                    page.host.showToast("已重置窗口几何，重启后生效");
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 退出
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                spacing: Md3.space.sm
                Item { Layout.fillWidth: true }
                MdButton {
                    text: "退出应用"
                    variant: "outlined"
                    danger: true
                    iconName: "power"
                    onClicked: quitDialog.open()
                }
            }
        }
    }

    MdConfirmDialog {
        id: quitDialog
        heading: "退出 Hyps Hub？"
        message: "正在运行的任务会被一并取消。"
        confirmText: "退出"
        danger: true
        onAccepted: AppControl.quitApplication()
    }
}
