import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 可展开区块：头部 56dp + 高度动画的内容区。 */
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool expanded: false

    default property alias contentData: body.data

    signal toggled(bool expanded)

    implicitHeight: Math.ceil(column.implicitHeight + Md3.space.xl * 2)
    implicitWidth: 320
    radius: Md3.shape.medium
    color: Theme.colors.surfaceContainerLow
    border.width: 1
    border.color: Theme.colors.outlineVariant
    clip: true

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Md3.space.lg
        spacing: 0

        Item {
            width: parent.width
            height: 32

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Md3.space.sm

                MdIcon {
                    visible: root.iconName.length > 0
                    name: root.iconName
                    size: 20
                    color: Theme.colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                MdText {
                    role: "titleSmall"
                    text: root.title
                    color: Theme.colors.onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }

                MdText {
                    visible: root.subtitle.length > 0
                    role: "bodySmall"
                    tone: "variant"
                    text: root.subtitle
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                }
            }

            MdIcon {
                name: "chevron-down"
                size: 22
                color: Theme.colors.onSurfaceVariant
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                rotation: root.expanded ? 180 : 0
                Behavior on rotation {
                    NumberAnimation { duration: Md3.motion.short3; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.expanded = !root.expanded;
                    root.toggled(root.expanded);
                }
            }
        }

        Item {
            id: bodyWrapper
            width: parent.width
            height: root.expanded ? body.implicitHeight + Md3.space.md : 0
            clip: true
            Behavior on height {
                NumberAnimation { duration: Md3.motion.short4; easing.type: Easing.OutCubic }
            }

            Item {
                id: body
                width: parent.width
                anchors.top: parent.top
                anchors.topMargin: Md3.space.md
                implicitHeight: childrenRect.height
            }
        }
    }
}
