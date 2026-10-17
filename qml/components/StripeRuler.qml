import QtQuick
import HypsHub 1.0

/* 45° 警戒线标尺 + 1px 细线，用于区块标题 */
Canvas {
    id: ruler

    property color lineColor: Theme.colors.rule
    property color stripeColor: Theme.colors.stripe
    property int stripeLength: 38
    implicitHeight: 8

    onLineColorChanged: requestPaint()
    onStripeColorChanged: requestPaint()
    onStripeLengthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);

        ctx.save();
        ctx.beginPath();
        ctx.rect(0, 0, Math.min(stripeLength, width), height);
        ctx.clip();
        ctx.strokeStyle = stripeColor;
        ctx.lineWidth = 2;
        for (let x = -height; x < stripeLength; x += 6) {
            ctx.beginPath();
            ctx.moveTo(x, height);
            ctx.lineTo(x + height, 0);
            ctx.stroke();
        }
        ctx.restore();

        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(Math.min(stripeLength + 10, width), Math.floor(height / 2) + 0.5);
        ctx.lineTo(width, Math.floor(height / 2) + 0.5);
        ctx.stroke();
    }
}
