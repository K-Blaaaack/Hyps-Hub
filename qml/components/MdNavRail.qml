import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 导航轨（Navigation rail）：80dp 宽，激活项用 56×32 的 secondaryContainer 胶囊指示器。
 *
 * pages 为 [{ id, label, icon }]；badges 为 { pageId: 数字 }，用于显示任务计数。
 * expanded 为 true 时切换成 256dp 的展开态（图标 + 文字横排）。
 */
Item {
    id: root

    property string currentPage: "home"
    property var pages: []
    property var badges: ({})
    property bool expanded: false
    property bool runtimeReady: false
    property string statusText: ""
    property string version: ""
    property string brandText: "Hyps Hub"

    signal navigate(string pageId)

    readonly property real railWidth: root.expanded ? Md3.size.navRailExpanded : Md3.size.navRail

    implicitWidth: root.railWidth
    implicitHeight: 640

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.surface
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.colors.outlineVariant
    }

    // 顶部品牌区
    Item {
        id: header
        width: root.width
        height: 72

        Row {
            anchors.left: parent.left
            anchors.leftMargin: root.expanded ? 24 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: root.expanded ? parent.width - 48 : parent.width
            spacing: 12

            Item {
                width: root.expanded ? 32 : header.width
                height: 32

                MdBrandMark {
                    anchors.centerIn: parent
                    markSize: 30
                }
            }

            MdText {
                visible: root.expanded
                role: "titleMedium"
                text: root.brandText
                color: Theme.colors.onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Column {
        id: items
        width: root.width
        anchors.top: header.bottom
        anchors.topMargin: 8
        spacing: 4

        Repeater {
            model: root.pages

            delegate: Item {
                id: navItem
                width: root.width
                height: 64
                activeFocusOnTab: true

                readonly property bool active: root.currentPage === modelData.id
                readonly property int badgeCount: {
                    const map = root.badges;
                    if (!map || map[modelData.id] === undefined) {
                        return 0;
                    }
                    return Number(map[modelData.id]);
                }

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Accessible.checked: navItem.active
                Accessible.focusable: true

                Keys.onReturnPressed: root.navigate(modelData.id)
                Keys.onSpacePressed: root.navigate(modelData.id)

                // 指示器（56×32 胶囊）
                Rectangle {
                    id: indicator
                    width: Md3.size.navRailIndicatorWidth
                    height: Md3.size.navRailIndicatorHeight
                    radius: height / 2
                    anchors.horizontalCenter: root.expanded ? undefined : parent.horizontalCenter
                    x: root.expanded ? 12 : 0
                    y: 4
                    color: navItem.active ? Theme.colors.secondaryContainer : "transparent"

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.colors.onSurface
                        opacity: mouseArea.containsMouse && !navItem.active ? Md3.state.hover : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Md3.motion.short2 }
                        }
                    }

                    MdIcon {
                        anchors.centerIn: parent
                        name: modelData.icon
                        size: 24
                        color: navItem.active ? Theme.colors.onSecondaryContainer
                                              : Theme.colors.onSurfaceVariant
                    }
                }

                // 展开态的标签
                MdText {
                    visible: root.expanded
                    role: "labelLarge"
                    text: modelData.label
                    color: navItem.active ? Theme.colors.onSurface : Theme.colors.onSurfaceVariant
                    x: 84
                    anchors.verticalCenter: indicator.verticalCenter
                }

                // 徽标
                Rectangle {
                    visible: navItem.badgeCount > 0
                    width: Math.max(16, badgeLabel.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Theme.colors.error
                    x: root.expanded ? 84 + 40 : indicator.x + indicator.width - 12
                    y: indicator.y + 2

                    Text {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: navItem.badgeCount > 9 ? "9+" : String(navItem.badgeCount)
                        color: Theme.colors.onError
                        font.family: App.uiFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }

                // 收起态的标签
                MdText {
                    visible: !root.expanded
                    role: "labelMedium"
                    text: modelData.label
                    color: navItem.active ? Theme.colors.onSurface : Theme.colors.onSurfaceVariant
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 38
                }

                // 焦点环
                Rectangle {
                    anchors.fill: indicator
                    anchors.margins: -3
                    radius: height / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.colors.primary
                    opacity: navItem.activeFocus ? 1 : 0
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        navItem.forceActiveFocus();
                        root.navigate(modelData.id);
                    }
                }
            }
        }
    }

    // 底部状态区
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        width: root.width
        spacing: 6

        Row {
            // 不能用 root.width：Row 会从最左边开始摆，状态点就贴到轨道边缘了
            spacing: 6
            visible: !root.expanded
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.runtimeReady ? Theme.colors.success : Theme.colors.error
                anchors.verticalCenter: parent.verticalCenter
            }

            MdText {
                visible: !root.expanded
                role: "labelSmall"
                text: root.runtimeReady ? "READY" : "OFFLINE"
                color: root.runtimeReady ? Theme.colors.success : Theme.colors.error
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            width: root.width
            spacing: 8
            visible: root.expanded
            anchors.left: parent.left
            anchors.leftMargin: 24

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.runtimeReady ? Theme.colors.success : Theme.colors.error
                anchors.verticalCenter: parent.verticalCenter
            }

            MdText {
                role: "labelMedium"
                text: root.statusText.length > 0
                      ? root.statusText
                      : (root.runtimeReady ? "组件就绪" : "组件未就绪")
                color: Theme.colors.onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MdText {
            visible: root.version.length > 0 && !root.expanded
            role: "labelSmall"
            text: root.version
            tone: "variant"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
