import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* MD3 线性进度：确定态按 value，不确定态跑循环动画。 */
Item {
    id: root
    Layout.fillWidth: true

    property real value: -1
    property real thickness: 4
    property color color: Theme.colors.primary

    readonly property bool indeterminate: root.value < 0

    implicitHeight: thickness
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Md3.alpha(root.color, 0.16)
    }

    Rectangle {
        id: bar
        height: parent.height
        radius: height / 2
        color: root.color
        width: root.indeterminate ? root.width * 0.3
                                  : Math.max(0, Math.min(1, root.value)) * root.width
        x: 0

        SequentialAnimation {
            running: root.indeterminate
            loops: Animation.Infinite
            NumberAnimation {
                target: bar
                property: "x"
                from: -bar.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutCubic
            }
            PauseAnimation { duration: 200 }
        }

        Behavior on width {
            enabled: !root.indeterminate
            NumberAnimation { duration: Md3.motion.medium2; easing.type: Easing.OutCubic }
        }
    }
}
