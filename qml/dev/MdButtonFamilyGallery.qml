import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/*
 * MdIconButton / MdFab / MdTooltip 的组件画廊（不进 qrc，只用于自检截图）。
 * 把所有变体、尺寸、禁用态排开展示；右下角静态弹一个 tooltip 证明外观。
 */
ApplicationWindow {
    id: win
    visible: true
    width: 1100
    height: 860
    color: Theme.colors.surface

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            x: 24
            y: 24
            width: win.width - 48
            spacing: 24

            MdText { role: "headlineSmall"; text: "MD3 按钮族渲染自检（IconButton / FAB / Tooltip）" }

            // ---- MdIconButton 变体 -------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                MdText { role: "titleMedium"; text: "MdIconButton · variant" }

                RowLayout {
                    spacing: 16
                    MdIconButton { iconName: "refresh"; variant: "standard"; tooltip: "刷新" }
                    MdIconButton { iconName: "save"; variant: "filled"; tooltip: "保存" }
                    MdIconButton { iconName: "copy"; variant: "tonal"; tooltip: "复制" }
                    MdIconButton { iconName: "external"; variant: "outlined"; tooltip: "打开" }
                }

                MdText { role: "titleSmall"; tone: "variant"; text: "danger" }

                RowLayout {
                    spacing: 16
                    MdIconButton { iconName: "trash"; variant: "standard"; danger: true; tooltip: "删除" }
                    MdIconButton { iconName: "trash"; variant: "filled"; danger: true }
                    MdIconButton { iconName: "trash"; variant: "tonal"; danger: true }
                    MdIconButton { iconName: "trash"; variant: "outlined"; danger: true }
                }

                MdText { role: "titleSmall"; tone: "variant"; text: "disabled" }

                RowLayout {
                    spacing: 16
                    MdIconButton { iconName: "refresh"; variant: "standard"; enabled: false }
                    MdIconButton { iconName: "save"; variant: "filled"; enabled: false }
                    MdIconButton { iconName: "copy"; variant: "tonal"; enabled: false }
                    MdIconButton { iconName: "external"; variant: "outlined"; enabled: false }
                }

                MdText { role: "titleSmall"; tone: "variant"; text: "size / iconSize" }

                RowLayout {
                    spacing: 16
                    MdIconButton { iconName: "search"; size: 32; iconSize: 20 }
                    MdIconButton { iconName: "search"; size: 40; iconSize: 24 }
                    MdIconButton { iconName: "search"; size: 48; iconSize: 28; variant: "filled" }
                    MdIconButton { iconName: "search"; size: 56; iconSize: 32; variant: "tonal" }
                }
            }

            // ---- MdFab --------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                MdText { role: "titleMedium"; text: "MdFab · size × variant" }

                RowLayout {
                    spacing: 24

                    ColumnLayout {
                        spacing: 8
                        MdText { role: "labelMedium"; tone: "variant"; text: "small" }
                        RowLayout {
                            spacing: 12
                            MdFab { iconName: "add"; size: "small"; variant: "primary" }
                            MdFab { iconName: "add"; size: "small"; variant: "secondary" }
                            MdFab { iconName: "add"; size: "small"; variant: "tertiary" }
                        }
                    }

                    ColumnLayout {
                        spacing: 8
                        MdText { role: "labelMedium"; tone: "variant"; text: "regular" }
                        RowLayout {
                            spacing: 12
                            MdFab { iconName: "add"; size: "regular"; variant: "primary" }
                            MdFab { iconName: "add"; size: "regular"; variant: "secondary" }
                            MdFab { iconName: "add"; size: "regular"; variant: "tertiary" }
                        }
                    }

                    ColumnLayout {
                        spacing: 8
                        MdText { role: "labelMedium"; tone: "variant"; text: "large" }
                        RowLayout {
                            spacing: 12
                            MdFab { iconName: "add"; size: "large"; variant: "primary" }
                            MdFab { iconName: "add"; size: "large"; variant: "secondary" }
                            MdFab { iconName: "add"; size: "large"; variant: "tertiary" }
                        }
                    }
                }

                MdText { role: "titleSmall"; tone: "variant"; text: "extended / disabled" }

                RowLayout {
                    spacing: 16
                    MdFab { iconName: "edit"; text: "新建任务"; variant: "primary" }
                    MdFab { iconName: "save"; text: "保存配置"; variant: "secondary" }
                    MdFab { iconName: "trash"; text: "清理日志"; variant: "tertiary" }
                    MdFab { iconName: "add"; enabled: false }
                    MdFab { iconName: "edit"; text: "禁用扩展"; enabled: false }
                }
            }

            // ---- MdTooltip -----------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                MdText { role: "titleMedium"; text: "MdTooltip · 悬停 500ms（这里静态弹一个用于截图）" }

                RowLayout {
                    spacing: 16
                    MdIconButton {
                        id: tipAnchor
                        iconName: "info"
                        variant: "tonal"
                        tooltip: "悬停我 500ms 出现提示"
                    }
                    MdIconButton { iconName: "clock"; variant: "outlined"; tooltip: "另一条提示" }
                    Item { Layout.fillWidth: true }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    MdTooltip {
        id: galleryTip
        text: "inverseSurface + labelMedium"
        target: tipAnchor
    }

    Timer {
        interval: 300
        running: true
        repeat: false
        onTriggered: galleryTip.showNow()
    }
}
