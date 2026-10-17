import QtQuick
import HypsHub 1.0

/* 进度条：确定进度用信号色填充；不确定态用 1.8s 的横向循环（禁止旋转 loading） */
Item {
    id: root

    property real value: 0
    property bool indeterminate: false
    property color trackColor: Theme.colors.ink3
    property color fillColor: Theme.colors.signal

    implicitHeight: 4

    Rectangle {
        anchors.fill: parent
        color: root.trackColor
    }

    Rectangle {
        visible: !root.indeterminate
        height: parent.height
        width: Math.max(0, Math.min(1, root.value)) * parent.width
        color: root.fillColor
    }

    Rectangle {
        id: runner
        visible: root.indeterminate
        height: parent.height
        width: parent.width * 0.28
        color: root.fillColor
        opacity: 0.9

        SequentialAnimation on x {
            running: root.indeterminate && root.visible
            loops: Animation.Infinite
            NumberAnimation {
                from: -runner.width
                to: runner.parent.width
                duration: 1800
                easing.type: Easing.InOutQuad
            }
        }
    }
}
