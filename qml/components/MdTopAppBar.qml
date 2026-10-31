import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 顶部应用栏（small app bar）：64dp 高，surface 底色，titleLarge 标题。
 *
 * 右侧 actions 是默认属性，页面把状态胶囊/按钮直接塞进去：
 *   MdTopAppBar {
 *       title: "游戏"
 *       subtitle: "GAMES"
 *       MdTag { text: "READY" }
 *       MdButton { text: "刷新"; variant: "text" }
 *   }
 * 页面滚动时把 scrolledUnder 设为 true，顶部会切换成 surfaceContainer 并出现分割线。
 */
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool scrolledUnder: false
    property bool showDivider: true

    default property alias actions: actionRow.data

    implicitHeight: Md3.size.topAppBarSmall

    Rectangle {
        anchors.fill: parent
        color: root.scrolledUnder ? Theme.colors.surfaceContainer : Theme.colors.surface

        Behavior on color {
            ColorAnimation { duration: Md3.motion.short3 }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.colors.outlineVariant
        visible: root.showDivider
        opacity: root.scrolledUnder ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short3 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Md3.space.xl
        anchors.rightMargin: Md3.space.xl
        spacing: Md3.space.md

        MdIcon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: 24
            color: Theme.colors.primary
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: root.width * 0.45
            spacing: 0

            MdText {
                role: "titleLarge"
                text: root.title
                color: Theme.colors.onSurface
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.width * 0.45)
            }

            MdText {
                visible: root.subtitle.length > 0
                role: "labelSmall"
                text: root.subtitle
                tone: "variant"
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: actionRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Md3.space.sm
        }
    }
}
