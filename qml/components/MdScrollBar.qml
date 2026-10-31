import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 滚动条：8dp 宽、圆角滑块，悬停/拖动加深。 */
ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    minimumSize: 0.08
    implicitWidth: Md3.size.scrollbar
    implicitHeight: Md3.size.scrollbar

    contentItem: Rectangle {
        implicitWidth: Md3.size.scrollbar
        implicitHeight: Md3.size.scrollbar
        radius: Md3.size.scrollbar / 2
        color: Md3.alpha(Theme.colors.outline,
                         root.pressed ? 0.72 : (root.hovered ? 0.56 : 0.40))
        visible: root.size > 0 && root.size < 1

        Behavior on color {
            ColorAnimation { duration: Md3.motion.short2 }
        }
    }

    background: Rectangle {
        color: "transparent"
    }
}
