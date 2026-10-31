import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 环形进度：Canvas 画弧，不确定态整体旋转。 */
Item {
    id: root

    property real value: -1
    property int size: 24
    property real thickness: 3
    property color color: Theme.colors.primary

    readonly property bool indeterminate: root.value < 0

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const side = Math.min(width, height);
            const line = root.thickness;
            const radius = (side - line) / 2;
            ctx.translate(width / 2, height / 2);
            ctx.lineWidth = line;
            ctx.lineCap = "round";

            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.18);
            ctx.beginPath();
            ctx.arc(0, 0, radius, 0, Math.PI * 2);
            ctx.stroke();

            ctx.strokeStyle = root.color;
            ctx.beginPath();
            if (root.indeterminate) {
                ctx.arc(0, 0, radius, -Math.PI / 2, Math.PI * 0.6);
            } else {
                ctx.arc(0, 0, radius, -Math.PI / 2,
                        -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, root.value)));
            }
            ctx.stroke();
        }

        Connections {
            target: root
            function onValueChanged() { canvas.requestPaint(); }
            function onColorChanged() { canvas.requestPaint(); }
            function onThicknessChanged() { canvas.requestPaint(); }
        }
    }

    RotationAnimator on rotation {
        running: root.indeterminate && root.visible
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 1100
    }
}
