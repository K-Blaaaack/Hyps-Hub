import QtQuick
import HypsHub 1.0

/*
 * Material Symbols 风格的线性图标（24×24 网格，1.75dp 描边，圆角端点）。
 *
 * 项目不随包分发字体文件，所以这里用 Canvas 按 Material 的几何规则自绘图标，
 * 保证任意尺寸下都是清晰矢量，并且颜色完全由 MD3 令牌控制。
 *
 * 用法：MdIcon { name: "settings"; size: 24; color: Theme.colors.onSurfaceVariant }
 */
Item {
    id: root

    property string name: "dot"
    property int size: 24
    property color color: Theme.colors.onSurface
    property real strokeWidth: 1.75
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onFilledChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const side = Math.min(width, height);
            if (side <= 0) {
                return;
            }
            const scale = side / 24;
            ctx.save();
            ctx.translate((width - side) / 2, (height - side) / 2);
            ctx.scale(scale, scale);
            ctx.strokeStyle = root.color;
            ctx.fillStyle = root.color;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            root.paint(ctx);
            ctx.restore();
        }
    }

    // 圆角矩形（24 网格坐标）
    function roundRect(ctx, x, y, w, h, r) {
        const radius = Math.min(r, w / 2, h / 2);
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + w - radius, y);
        ctx.quadraticCurveTo(x + w, y, x + w, y + radius);
        ctx.lineTo(x + w, y + h - radius);
        ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
        ctx.lineTo(x + radius, y + h);
        ctx.quadraticCurveTo(x, y + h, x, y + h - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.closePath();
    }

    function circle(ctx, cx, cy, r) {
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
    }

    function line(ctx, x1, y1, x2, y2) {
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
    }

    function polyline(ctx, points) {
        ctx.beginPath();
        ctx.moveTo(points[0], points[1]);
        for (let i = 2; i + 1 < points.length; i += 2) {
            ctx.lineTo(points[i], points[i + 1]);
        }
        ctx.stroke();
    }

    function paint(ctx) {
        switch (root.name) {
        case "home":
            polyline(ctx, [3.5, 10.5, 12, 3.5, 20.5, 10.5]);
            ctx.beginPath();
            ctx.moveTo(5.5, 9.5);
            ctx.lineTo(5.5, 20);
            ctx.lineTo(18.5, 20);
            ctx.lineTo(18.5, 9.5);
            ctx.stroke();
            roundRect(ctx, 10, 14, 4, 6, 0.8);
            ctx.stroke();
            break;
        case "games":
            roundRect(ctx, 2.5, 7, 19, 10.5, 4.5);
            ctx.stroke();
            line(ctx, 7.5, 10.6, 7.5, 14.0);
            line(ctx, 5.8, 12.3, 9.2, 12.3);
            circle(ctx, 16.4, 11.2, 1.05);
            ctx.fill();
            circle(ctx, 18.2, 13.6, 1.05);
            ctx.fill();
            break;
        case "tasks":
        case "list":
            for (let i = 0; i < 3; ++i) {
                const y = 6.5 + i * 5.5;
                circle(ctx, 4.4, y, 1.15);
                ctx.stroke();
                line(ctx, 8.2, y, 19.6, y);
            }
            break;
        case "config":
        case "tune":
            line(ctx, 3.5, 7, 20.5, 7);
            line(ctx, 3.5, 12, 20.5, 12);
            line(ctx, 3.5, 17, 20.5, 17);
            circle(ctx, 8.5, 7, 2.1);
            ctx.fill();
            circle(ctx, 15.5, 12, 2.1);
            ctx.fill();
            circle(ctx, 10, 17, 2.1);
            ctx.fill();
            break;
        case "diagnostics":
        case "monitor-heart":
            roundRect(ctx, 2.5, 4.5, 19, 13, 2.2);
            ctx.stroke();
            polyline(ctx, [5.5, 11.2, 8.2, 11.2, 9.8, 8.2, 11.8, 14.2, 13.4, 11.2, 18.5, 11.2]);
            line(ctx, 9, 20.5, 15, 20.5);
            line(ctx, 12, 17.5, 12, 20.5);
            break;
        case "settings":
            for (let i = 0; i < 8; ++i) {
                const angle = (Math.PI / 4) * i;
                const x1 = 12 + Math.cos(angle) * 6.6;
                const y1 = 12 + Math.sin(angle) * 6.6;
                const x2 = 12 + Math.cos(angle) * 9.0;
                const y2 = 12 + Math.sin(angle) * 9.0;
                line(ctx, x1, y1, x2, y2);
            }
            circle(ctx, 12, 12, 6.6);
            ctx.stroke();
            circle(ctx, 12, 12, 2.6);
            ctx.stroke();
            break;
        case "about":
        case "info":
            circle(ctx, 12, 12, 9);
            ctx.stroke();
            circle(ctx, 12, 7.7, 1.15);
            ctx.fill();
            line(ctx, 12, 11.2, 12, 16.6);
            break;
        case "refresh":
            ctx.beginPath();
            ctx.arc(12, 12, 7.2, Math.PI * 0.85, Math.PI * 2.15);
            ctx.stroke();
            polyline(ctx, [16.4, 2.9, 18.7, 6.4, 14.7, 7.1]);
            break;
        case "check":
            polyline(ctx, [4.8, 12.6, 9.6, 17.4, 19.2, 6.8]);
            break;
        case "check-circle":
            circle(ctx, 12, 12, 9);
            ctx.stroke();
            polyline(ctx, [7.6, 12.2, 10.8, 15.4, 16.6, 8.8]);
            break;
        case "close":
            line(ctx, 6.2, 6.2, 17.8, 17.8);
            line(ctx, 17.8, 6.2, 6.2, 17.8);
            break;
        case "chevron-right":
            polyline(ctx, [9.5, 5.5, 16, 12, 9.5, 18.5]);
            break;
        case "chevron-down":
            polyline(ctx, [5.5, 9.5, 12, 16, 18.5, 9.5]);
            break;
        case "chevron-left":
            polyline(ctx, [14.5, 5.5, 8, 12, 14.5, 18.5]);
            break;
        case "chevron-up":
            polyline(ctx, [5.5, 14.5, 12, 8, 18.5, 14.5]);
            break;
        case "arrow-left":
            line(ctx, 20, 12, 4.5, 12);
            polyline(ctx, [10.5, 5.8, 4.2, 12, 10.5, 18.2]);
            break;
        case "arrow-right":
            line(ctx, 4, 12, 19.5, 12);
            polyline(ctx, [13.5, 5.8, 19.8, 12, 13.5, 18.2]);
            break;
        case "arrow-up":
            line(ctx, 12, 20, 12, 4.5);
            polyline(ctx, [5.8, 10.5, 12, 4.2, 18.2, 10.5]);
            break;
        case "arrow-down":
            line(ctx, 12, 4, 12, 19.5);
            polyline(ctx, [5.8, 13.5, 12, 19.8, 18.2, 13.5]);
            break;
        case "folder":
            polyline(ctx, [3, 7.2, 9.4, 7.2, 11.2, 9.4, 21, 9.4]);
            ctx.beginPath();
            ctx.moveTo(3, 7.2);
            ctx.lineTo(3, 18.6);
            ctx.lineTo(21, 18.6);
            ctx.lineTo(21, 9.4);
            ctx.lineTo(11.2, 9.4);
            ctx.lineTo(9.4, 7.2);
            ctx.closePath();
            ctx.stroke();
            break;
        case "file":
            polyline(ctx, [6, 3.2, 14.2, 3.2, 18.6, 7.6, 18.6, 20.8, 6, 20.8, 6, 3.2]);
            polyline(ctx, [14.2, 3.2, 14.2, 7.6, 18.6, 7.6]);
            break;
        case "play":
            ctx.beginPath();
            ctx.moveTo(8, 4.8);
            ctx.lineTo(19.4, 12);
            ctx.lineTo(8, 19.2);
            ctx.closePath();
            if (root.filled) {
                ctx.fill();
            } else {
                ctx.stroke();
            }
            break;
        case "stop":
            roundRect(ctx, 6.2, 6.2, 11.6, 11.6, 1.6);
            if (root.filled) {
                ctx.fill();
            } else {
                ctx.stroke();
            }
            break;
        case "copy":
            roundRect(ctx, 8.6, 8.6, 11.8, 11.8, 2);
            ctx.stroke();
            polyline(ctx, [5.6, 15.4, 4.2, 15.4, 4.2, 3.8, 15.8, 3.8, 15.8, 5.2]);
            break;
        case "search":
            circle(ctx, 10.8, 10.8, 6.6);
            ctx.stroke();
            line(ctx, 15.6, 15.6, 20.4, 20.4);
            break;
        case "filter":
            polyline(ctx, [3.4, 5.2, 20.6, 5.2, 13.8, 12.6, 13.8, 19.6, 10.2, 17.4, 10.2, 12.6]);
            break;
        case "warning":
            polyline(ctx, [12, 3.4, 21.4, 20.2, 2.6, 20.2, 12, 3.4]);
            line(ctx, 12, 9.2, 12, 14.2);
            circle(ctx, 12, 17.2, 1.05);
            ctx.fill();
            break;
        case "error":
        case "danger":
            circle(ctx, 12, 12, 9);
            ctx.stroke();
            line(ctx, 12, 7.2, 12, 13.4);
            circle(ctx, 12, 16.6, 1.05);
            ctx.fill();
            break;
        case "external":
            polyline(ctx, [13.4, 4.4, 19.6, 4.4, 19.6, 10.6]);
            line(ctx, 19.4, 4.6, 11.4, 12.6);
            polyline(ctx, [16.4, 14.2, 16.4, 19.6, 4.4, 19.6, 4.4, 7.6, 9.8, 7.6]);
            break;
        case "terminal":
            roundRect(ctx, 2.6, 4.4, 18.8, 15.2, 2.2);
            ctx.stroke();
            polyline(ctx, [6.4, 9.6, 9.2, 12.2, 6.4, 14.8]);
            line(ctx, 11.4, 15.2, 16.4, 15.2);
            break;
        case "save":
            polyline(ctx, [4.2, 4.2, 16.2, 4.2, 19.8, 7.8, 19.8, 19.8, 4.2, 19.8, 4.2, 4.2]);
            roundRect(ctx, 7.6, 4.2, 8.2, 5.4, 0.6);
            ctx.stroke();
            roundRect(ctx, 7.4, 13, 9.2, 6.8, 0.6);
            ctx.stroke();
            break;
        case "trash":
            line(ctx, 3.8, 6.6, 20.2, 6.6);
            polyline(ctx, [9.2, 6.4, 9.2, 3.8, 14.8, 3.8, 14.8, 6.4]);
            polyline(ctx, [5.8, 6.8, 6.8, 20.2, 17.2, 20.2, 18.2, 6.8]);
            line(ctx, 10.2, 10.4, 10.2, 16.8);
            line(ctx, 13.8, 10.4, 13.8, 16.8);
            break;
        case "add":
            line(ctx, 12, 4.6, 12, 19.4);
            line(ctx, 4.6, 12, 19.4, 12);
            break;
        case "edit":
            polyline(ctx, [4, 20, 4.4, 16.2, 16.4, 4.2, 19.8, 7.6, 7.8, 19.6, 4, 20]);
            break;
        case "more-vert":
            circle(ctx, 12, 5.4, 1.5);
            ctx.fill();
            circle(ctx, 12, 12, 1.5);
            ctx.fill();
            circle(ctx, 12, 18.6, 1.5);
            ctx.fill();
            break;
        case "download":
            line(ctx, 12, 3.6, 12, 15.2);
            polyline(ctx, [6.6, 9.8, 12, 15.2, 17.4, 9.8]);
            polyline(ctx, [4.2, 15.8, 4.2, 20.4, 19.8, 20.4, 19.8, 15.8]);
            break;
        case "upload":
            line(ctx, 12, 15.4, 12, 3.8);
            polyline(ctx, [6.6, 9.2, 12, 3.8, 17.4, 9.2]);
            polyline(ctx, [4.2, 15.8, 4.2, 20.4, 19.8, 20.4, 19.8, 15.8]);
            break;
        case "link":
            polyline(ctx, [10.4, 13.6, 13.6, 10.4]);
            ctx.beginPath();
            ctx.arc(8.4, 15.6, 4.2, Math.PI * 1.15, Math.PI * 1.95);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(15.6, 8.4, 4.2, Math.PI * 0.15, Math.PI * 0.95);
            ctx.stroke();
            break;
        case "clock":
            circle(ctx, 12, 12, 9);
            ctx.stroke();
            polyline(ctx, [12, 6.8, 12, 12.4, 16.2, 14.8]);
            break;
        case "git":
            circle(ctx, 6.6, 5.6, 2.4);
            ctx.stroke();
            circle(ctx, 6.6, 18.4, 2.4);
            ctx.stroke();
            circle(ctx, 17.4, 8.6, 2.4);
            ctx.stroke();
            line(ctx, 6.6, 8.2, 6.6, 15.8);
            ctx.beginPath();
            ctx.moveTo(17.4, 11.2);
            ctx.lineTo(17.4, 13.4);
            ctx.quadraticCurveTo(17.4, 15.6, 14.8, 15.6);
            ctx.lineTo(9.2, 15.6);
            ctx.stroke();
            break;
        case "monitor":
            roundRect(ctx, 2.6, 4.4, 18.8, 12.6, 2.2);
            ctx.stroke();
            line(ctx, 8.6, 20.4, 15.4, 20.4);
            line(ctx, 12, 17.2, 12, 20.4);
            break;
        case "shield":
            polyline(ctx, [12, 3, 20, 6.2, 20, 12.2, 12, 21, 4, 12.2, 4, 6.2, 12, 3]);
            polyline(ctx, [8.6, 12, 11.2, 14.6, 15.6, 9.8]);
            break;
        case "power":
            ctx.beginPath();
            ctx.arc(12, 12.6, 7.4, Math.PI * 0.72, Math.PI * 0.28, false);
            ctx.stroke();
            line(ctx, 12, 3.4, 12, 11.4);
            break;
        case "code":
            polyline(ctx, [8.4, 7.6, 3.6, 12, 8.4, 16.4]);
            polyline(ctx, [15.6, 7.6, 20.4, 12, 15.6, 16.4]);
            break;
        case "grid":
            roundRect(ctx, 3.6, 3.6, 7, 7, 1.2);
            ctx.stroke();
            roundRect(ctx, 13.4, 3.6, 7, 7, 1.2);
            ctx.stroke();
            roundRect(ctx, 3.6, 13.4, 7, 7, 1.2);
            ctx.stroke();
            roundRect(ctx, 13.4, 13.4, 7, 7, 1.2);
            ctx.stroke();
            break;
        case "layers":
            polyline(ctx, [12, 3.4, 20.6, 8, 12, 12.6, 3.4, 8, 12, 3.4]);
            polyline(ctx, [3.4, 12, 12, 16.6, 20.6, 12]);
            polyline(ctx, [3.4, 16, 12, 20.6, 20.6, 16]);
            break;
        case "dot":
        default:
            circle(ctx, 12, 12, 3.4);
            ctx.fill();
            break;
        }
    }
}
