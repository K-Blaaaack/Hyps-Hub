import QtQuick
import HypsHub 1.0

/* 自绘线性图标：1.5px 线宽，统一来源，不使用 emoji / 第三方图标 */
Canvas {
    id: canvas

    property string name: "home"
    property color color: Theme.colors.muted

    width: 20
    height: 20
    antialiasing: true

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = color;
        ctx.fillStyle = color;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "square";

        const s = Math.min(width, height);
        const step = s / 20;

        function line(x1, y1, x2, y2) {
            ctx.beginPath();
            ctx.moveTo(x1 * step, y1 * step);
            ctx.lineTo(x2 * step, y2 * step);
            ctx.stroke();
        }

        if (name === "home") {
            line(3, 3, 9, 3); line(3, 3, 3, 9);
            line(11, 3, 17, 3); line(17, 3, 17, 9);
            line(3, 11, 3, 17); line(3, 17, 9, 17);
            line(11, 17, 17, 17); line(17, 11, 17, 17);
        } else if (name === "games") {
            ctx.strokeRect(3 * step, 4 * step, 14 * step, 12 * step);
            ctx.beginPath();
            ctx.moveTo(9 * step, 8 * step);
            ctx.lineTo(14 * step, 10 * step);
            ctx.lineTo(9 * step, 12 * step);
            ctx.closePath();
            ctx.stroke();
        } else if (name === "tasks") {
            line(3, 4, 17, 4); line(3, 10, 17, 10); line(3, 16, 17, 16);
            line(3, 4, 3, 4); line(3, 10, 3, 10); line(3, 16, 3, 16);
            ctx.fillRect(3 * step, 3 * step, 2 * step, 2 * step);
            ctx.fillRect(3 * step, 9 * step, 2 * step, 2 * step);
            ctx.fillRect(3 * step, 15 * step, 2 * step, 2 * step);
        } else if (name === "config") {
            line(3, 5, 17, 5); line(3, 10, 17, 10); line(3, 15, 17, 15);
            ctx.fillRect(6 * step, 3.5 * step, 2 * step, 3 * step);
            ctx.fillRect(12 * step, 8.5 * step, 2 * step, 3 * step);
            ctx.fillRect(8 * step, 13.5 * step, 2 * step, 3 * step);
        } else if (name === "diagnostics") {
            line(2, 11, 5, 11); line(5, 11, 7, 5); line(7, 5, 10, 16);
            line(10, 16, 12, 9); line(12, 9, 14, 11); line(14, 11, 18, 11);
        } else if (name === "settings") {
            ctx.beginPath();
            ctx.arc(10 * step, 10 * step, 4.5 * step, 0, Math.PI * 2);
            ctx.stroke();
            line(10, 2, 10, 4); line(10, 16, 10, 18);
            line(2, 10, 4, 10); line(16, 10, 18, 10);
        }
    }
}
