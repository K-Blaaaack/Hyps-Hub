import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

ApplicationWindow {
    id: win
    visible: true
    width: 1200
    height: 900
    color: Theme.colors.surface

    property var iconNames: ["home", "games", "tasks", "config", "diagnostics", "settings",
                             "about", "refresh", "check", "close", "chevron-right", "chevron-down",
                             "folder", "file", "play", "stop", "copy", "search", "filter", "warning",
                             "error", "external", "terminal", "save", "trash", "add", "edit",
                             "more-vert", "download", "upload", "link", "clock", "git", "monitor",
                             "shield", "power", "code", "grid", "layers", "dot"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        MdText { role: "headlineSmall"; text: "MD3 核心组件渲染自检" }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: win.iconNames
                delegate: Rectangle {
                    width: 64; height: 64; radius: 8
                    color: Theme.colors.surfaceContainerLow
                    MdIcon {
                        anchors.centerIn: parent
                        name: modelData
                        size: 24
                        color: Theme.colors.onSurface
                    }
                }
            }
        }

        RowLayout {
            spacing: 12
            MdButton { text: "主要操作"; variant: "filled"; iconName: "save" }
            MdButton { text: "次要"; variant: "tonal"; iconName: "refresh" }
            MdButton { text: "描边"; variant: "outlined" }
            MdButton { text: "文字"; variant: "text"; iconName: "copy" }
            MdButton { text: "危险"; variant: "filled"; danger: true; iconName: "trash" }
            MdButton { text: "禁用"; enabled: false }
        }

        RowLayout {
            spacing: 16
            Layout.fillWidth: true

            MdCard {
                Layout.preferredWidth: 260
                Layout.preferredHeight: 120
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    MdText { role: "titleMedium"; text: "填充卡片" }
                    MdText { role: "bodySmall"; tone: "variant"; text: "surfaceContainerHighest"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            MdCard {
                variant: "elevated"
                Layout.preferredWidth: 260
                Layout.preferredHeight: 120
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    MdText { role: "titleMedium"; text: "抬升卡片" }
                    MdText { role: "bodySmall"; tone: "variant"; text: "surfaceContainerLow + 阴影"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            MdCard {
                variant: "outlined"
                Layout.preferredWidth: 260
                Layout.preferredHeight: 120
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    MdText { role: "titleMedium"; text: "描边卡片" }
                    MdText { role: "bodySmall"; tone: "variant"; text: "surface + outlineVariant"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
        }

        RowLayout {
            spacing: 16
            Layout.fillWidth: true
            MdTextField {
                Layout.preferredWidth: 280
                label: "game.exe"
                text: "/path/to/Arknights.exe"
                monospace: true
            }
            MdTextField {
                Layout.preferredWidth: 280
                label: "空字段"
                placeholderText: "请输入"
            }
            MdTextField {
                Layout.preferredWidth: 280
                label: "错误态"
                text: "bad value"
                error: true
                supportingText: "路径不存在"
            }
            MdTextField {
                Layout.preferredWidth: 240
                variant: "outlined"
                label: "描边输入框"
                text: "umu-dwproton"
            }
        }

        Item { Layout.fillHeight: true }
    }
}
