import QtQuick
import QtQuick.Shapes
import HypsHub 1.0

/*
 * Ark 风格技术面板：零圆角、1px 细线、左上/右下 45° 切角、单条左侧强边、
 * 右上/左下取景框角标。内容默认放进带内边距的 contentItem。
 */
Item {
    id: root

    property real cut: 10
    property color fillColor: Theme.colors.ink2
    property color borderColor: Theme.colors.line
    property color accentColor: Theme.colors.signal
    property bool accentVisible: true
    property bool brackets: true
    property real contentMargin: 20
    property real borderWidth: 1

    property alias contentItem: contentArea
    default property alias contentData: contentArea.data

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.borderColor
            fillColor: root.fillColor
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap

            startX: root.cut
            startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height - root.cut }
            PathLine { x: root.width - root.cut; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: root.cut }
            PathLine { x: root.cut; y: 0 }
        }
    }

    // 唯一的强边：左侧 2px 信号色
    Rectangle {
        visible: root.accentVisible
        x: 0
        y: root.cut
        width: 2
        height: Math.max(0, root.height - root.cut * 2)
        color: root.accentColor
    }

    // 取景框角标（右上 + 左下）
    Rectangle {
        visible: root.brackets
        width: 12
        height: 1
        color: root.accentColor
        opacity: 0.7
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 8
        anchors.topMargin: 8
    }
    Rectangle {
        visible: root.brackets
        width: 1
        height: 12
        color: root.accentColor
        opacity: 0.7
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 8
        anchors.topMargin: 8
    }
    Rectangle {
        visible: root.brackets
        width: 12
        height: 1
        color: root.accentColor
        opacity: 0.7
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.bottomMargin: 8
    }
    Rectangle {
        visible: root.brackets
        width: 1
        height: 12
        color: root.accentColor
        opacity: 0.7
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.bottomMargin: 8
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.leftMargin: root.contentMargin
        anchors.rightMargin: root.contentMargin
        anchors.topMargin: root.contentMargin
        anchors.bottomMargin: root.contentMargin
    }
}
