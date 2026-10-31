import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 复选框（Checkbox）。
 *
 * 规范要点：18dp 方框、圆角 2dp（shape.extraSmall 的一半）；未选中 = 2dp
 * onSurfaceVariant 描边；选中 = primary 底 + onPrimary 勾（MdIcon "check" 14dp）；
 * indeterminate = primary 底 + onPrimary 横线。右侧标签 bodyLarge、间距 8dp，
 * 整行 40dp 可点（方框居中在 40dp 触控区内）。
 * 状态层：hover 8% / focus 10% / pressed 10%，40dp 圆形叠在方框下。
 *
 * 实现说明：T.CheckBox 的 indicator 部件在 Qt 6.10 下限制多，这里用 FocusScope
 * 自己拼（同 MdTextField 的做法），键盘 activeFocusOnTab + 空格切换。
 *
 * 用法：
 *   MdCheckbox { text: "自动更新"; checked: cfg.auto; onToggled: cfg.auto = value }
 */
FocusScope {
    id: control

    property bool checked: false
    property bool indeterminate: false
    property string text: ""

    signal toggled(bool value)

    readonly property real boxSize: 18
    readonly property real targetSize: 40
    readonly property real boxInset: (control.targetSize - control.boxSize) / 2        // 11
    readonly property real textLeft: control.boxInset + control.boxSize + Md3.space.sm // 37
    readonly property bool marked: control.checked || control.indeterminate

    implicitHeight: control.targetSize
    implicitWidth: control.text.length > 0
                   ? control.textLeft + label.implicitWidth
                   : control.targetSize
    activeFocusOnTab: true

    readonly property color boxColor: control.marked
                                      ? (control.enabled ? Theme.colors.primary
                                                         : Md3.alpha(Theme.colors.onSurface,
                                                                     Md3.state.disabledContainer))
                                      : "transparent"
    readonly property color borderColor: control.enabled
                                         ? Theme.colors.onSurfaceVariant
                                         : Md3.alpha(Theme.colors.onSurface,
                                                     Md3.state.disabledContent)
    readonly property color contentColor: control.enabled
                                          ? Theme.colors.onPrimary
                                          : Md3.alpha(Theme.colors.onSurface,
                                                      Md3.state.disabledContent)
    readonly property color stateColor: control.marked ? Theme.colors.primary
                                                       : Theme.colors.onSurface

    Accessible.role: Accessible.CheckBox
    Accessible.name: control.text
    Accessible.checkable: true
    Accessible.checked: control.checked
    Accessible.focusable: true
    Accessible.focused: control.activeFocus

    function toggle() {
        if (!control.enabled) {
            return;
        }
        control.indeterminate = false;
        control.checked = !control.checked;
        control.toggled(control.checked);
    }

    Keys.onSpacePressed: control.toggle()
    Keys.onEnterPressed: control.toggle()
    Keys.onReturnPressed: control.toggle()

    // --- 状态层 -------------------------------------------------------------
    Rectangle {
        id: stateLayer
        width: control.targetSize
        height: control.targetSize
        radius: width / 2
        x: control.boxInset + control.boxSize / 2 - width / 2
        y: (control.targetSize - height) / 2
        color: control.stateColor
        opacity: !control.enabled ? 0
                                  : (mouse.pressed ? Md3.state.pressed
                                                   : (control.activeFocus ? Md3.state.focus
                                                                          : (mouse.containsMouse
                                                                             ? Md3.state.hover : 0)))
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
        }
    }

    // --- 方框 ---------------------------------------------------------------
    Rectangle {
        id: box
        x: control.boxInset
        y: (control.targetSize - control.boxSize) / 2
        width: control.boxSize
        height: control.boxSize
        radius: Md3.shape.extraSmall / 2
        color: control.boxColor
        border.width: control.marked ? 0 : 2
        border.color: control.borderColor

        Behavior on color {
            ColorAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
        }

        MdIcon {
            anchors.centerIn: parent
            name: "check"
            size: 14
            color: control.contentColor
            visible: control.checked && !control.indeterminate
            opacity: control.checked && !control.indeterminate ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: control.indeterminate
            width: 10
            height: 2
            radius: height / 2
            color: control.contentColor
        }
    }

    // --- 焦点环 -------------------------------------------------------------
    Rectangle {
        x: box.x - Md3.space.xs
        y: box.y - Md3.space.xs
        width: box.width + Md3.space.sm
        height: box.height + Md3.space.sm
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: control.enabled ? Theme.colors.primary : control.borderColor
        opacity: control.activeFocus ? 0.9 : 0
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2 }
        }
    }

    // --- 标签 ---------------------------------------------------------------
    MdText {
        id: label
        visible: control.text.length > 0
        role: "bodyLarge"
        text: control.text
        color: control.enabled ? Theme.colors.onSurface
                               : Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent)
        x: control.textLeft
        y: 0
        width: Math.max(0, control.width - control.textLeft)
        height: control.targetSize
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            control.forceActiveFocus();
            control.toggle();
        }
    }
}
