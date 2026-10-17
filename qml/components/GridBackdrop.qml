import QtQuick
import HypsHub 1.0

/* 基底：近黑墨底 + 64px 蓝图网格 + 4% 噪点 + 径向暗角（方舟双签名纹理之一） */
Item {
    id: root

    property int gridStep: 64
    property bool vignette: true

    Canvas {
        id: grid
        anchors.fill: parent
        property bool dark: Theme.colors.dark
        property color gridColor: Theme.colors.gridLine

        onDarkChanged: requestPaint()
        onGridColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 1;
            for (let x = 0; x < width; x += root.gridStep) {
                ctx.beginPath();
                ctx.moveTo(x + 0.5, 0);
                ctx.lineTo(x + 0.5, height);
                ctx.stroke();
            }
            for (let y = 0; y < height; y += root.gridStep) {
                ctx.beginPath();
                ctx.moveTo(0, y + 0.5);
                ctx.lineTo(width, y + 0.5);
                ctx.stroke();
            }

            if (root.vignette) {
                const cx = width * 0.5;
                const cy = height * 0.42;
                const gradient = ctx.createRadialGradient(cx, cy, Math.min(width, height) * 0.12,
                                                          cx, cy, Math.max(width, height) * 0.78);
                gradient.addColorStop(0, "rgba(0,0,0,0)");
                gradient.addColorStop(1, dark ? "rgba(0,0,0,0.55)" : "rgba(255,255,255,0.5)");
                ctx.fillStyle = gradient;
                ctx.fillRect(0, 0, width, height);
            }
        }
    }

    Image {
        anchors.fill: parent
        source: "qrc:/assets/noise.png"
        fillMode: Image.Tile
        opacity: Theme.colors.dark ? 0.55 : 0.25
    }
}
