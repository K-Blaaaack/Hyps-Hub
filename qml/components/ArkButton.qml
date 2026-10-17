import QtQuick
import QtQuick.Controls
import HypsHub 1.0

/* Ark 操作按钮：方角 + 1px 描边 + 左侧 2px 信号条 + 44px 最小高度 */
Button {
    id: control

    property bool primary: false
    property bool danger: false
    property bool ghost: false

    implicitHeight: 44
    leftPadding: 20
    rightPadding: 20
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    font.family: App.uiFontFamily
    font.pixelSize: 11
    font.weight: Font.DemiBold
    font.letterSpacing: 1.4
    font.capitalization: Font.AllUppercase

    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? Theme.colors.disabled
               : (control.primary ? Theme.colors.paper : Theme.colors.paper2)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Item {
        ChamferedPanel {
            anchors.fill: parent
            cut: 7
            contentMargin: 0
            brackets: false
            fillColor: control.ghost
                      ? (control.down ? Theme.colors.ink3 : "transparent")
                      : (control.down ? Theme.colors.ink4
                         : (control.hovered ? Theme.colors.ink3 : Theme.colors.ink2))
            borderColor: control.activeFocus ? Theme.colors.signal
                        : (control.hovered ? Theme.colors.lineHover : Theme.colors.line)
            accentColor: control.danger ? Theme.colors.danger : Theme.colors.signal
            accentVisible: !control.ghost
        }

        Rectangle {
            visible: control.activeFocus
            anchors.fill: parent
            anchors.margins: -3
            color: "transparent"
            border.width: 2
            border.color: Theme.colors.signal
        }

        scale: control.down ? 0.98 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }
}
