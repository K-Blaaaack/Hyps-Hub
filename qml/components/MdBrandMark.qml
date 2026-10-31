import QtQuick
import HypsHub 1.0

/*
 * 品牌标识：Hyps Hub 的 H 字标（纯字标，不加装饰点）。
 *
 * 颜色跟随主题（深色 #d0bcff，浅色 #6750a4），所以 SVG 是透明底、
 * 可以直接压在卡片/导航轨上；需要「图标底板」时在外面套一个 Rectangle，
 * 底板色请用 Theme.colors.surface（filled 卡片是 surfaceContainerHighest，
 * 同色底板会完全看不见）。
 *
 *   MdBrandMark { markSize: 30 }                      // 裸标
 *   Rectangle { color: Theme.colors.surface; radius: Md3.shape.medium
 *               width: 64; height: 64
 *               MdBrandMark { anchors.centerIn: parent; markSize: 44 } }
 */
Image {
    id: root

    // 目标显示尺寸；同时用作栅格化分辨率，保证小尺寸不发虚
    property int markSize: 32

    width: root.markSize
    height: root.markSize
    source: Theme.dark ? "qrc:/assets/hyps-hub.svg" : "qrc:/assets/hyps-hub-light.svg"
    sourceSize: Qt.size(root.markSize, root.markSize)
    fillMode: Image.PreserveAspectFit
    smooth: true
}
