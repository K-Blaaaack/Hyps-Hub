import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 开关（Switch）。
 *
 * 规范要点：轨道 52×32、圆角 = 高/2（16）；关闭 = surfaceContainerHighest 底
 * + 2dp outline 描边 + 16dp onSurfaceVariant 圆点；开启 = primary 底
 * + 24dp onPrimary 圆点（内含 check 语义图标）；按下时圆点放大到 28dp。
 * 状态层：hover 8% / focus 10% / pressed 10%，圆形叠在圆点下方，不溢出控件边界。
 *
 * 实现说明：不用 T.Switch —— 它的轨道/圆点没有可覆写的部件，Qt 6.10 里改
 * contentItem 容易踩 "Cannot assign to non-existent property"。这里用 FocusScope
 * 自己拼（与 MdTextField 同一套做法），键盘走 activeFocusOnTab + Keys（空格切换）。
 *
 * 用法：
 *   MdSwitch { checked: cfg.enabled; onToggled: cfg.enabled = value }
 */
FocusScope {
    id: control

    property bool checked: false
    property string accessibleName: ""

    signal toggled(bool value)

    implicitWidth: Md3.size.switchTrackWidth
    implicitHeight: Md3.size.switchTrackHeight
    activeFocusOnTab: true

    readonly property real thumbOffSize: Md3.size.switchThumb - Md3.space.sm   // 16
    readonly property real thumbOnSize: Md3.size.switchThumb                   // 24
    readonly property real thumbSize: mouse.pressed
                                      ? Md3.size.switchThumbPressed            // 28
                                      : (control.checked ? control.thumbOnSize : control.thumbOffSize)

    // 圆点中心：关闭贴左（距边 16）、开启贴右（距边 16）；切换时用 Behavior 平移。
    property real thumbCenter: control.checked
                               ? control.width - Md3.size.switchTrackHeight / 2
                               : Md3.size.switchTrackHeight / 2

    readonly property color trackColor: control.checked
                                        ? Theme.colors.primary
                                        : Theme.colors.surfaceContainerHighest
    readonly property color thumbColor: control.checked
                                        ? Theme.colors.onPrimary
                                        : Theme.colors.onSurfaceVariant
    readonly property color stateColor: control.checked
                                        ? Theme.colors.onPrimary
                                        : Theme.colors.onSurface
    readonly property color disabledTrackColor: Md3.alpha(Theme.colors.onSurface,
                                                          Md3.state.disabledContainer)
    readonly property color disabledThumbColor: control.checked
                                                ? Theme.colors.surface
                                                : Md3.alpha(Theme.colors.onSurface,
                                                            Md3.state.disabledContent)

    Accessible.role: Accessible.Switch
    Accessible.name: control.accessibleName.length > 0 ? control.accessibleName : "开关"
    Accessible.checkable: true
    Accessible.checked: control.checked
    Accessible.focusable: true
    Accessible.focused: control.activeFocus

    Behavior on thumbCenter {
        NumberAnimation { duration: Md3.motion.short4; easing.type: Easing.InOutCubic }
    }

    function toggle() {
        if (!control.enabled) {
            return;
        }
        control.checked = !control.checked;
        control.toggled(control.checked);
    }

    Keys.onSpacePressed: control.toggle()
    Keys.onEnterPressed: control.toggle()
    Keys.onReturnPressed: control.toggle()

    // --- 轨道 ---------------------------------------------------------------
    Rectangle {
        id: track
        width: control.width
        height: control.height
        radius: height / 2
        color: !control.enabled ? control.disabledTrackColor : control.trackColor
        border.width: control.checked ? 0 : 2
        border.color: !control.enabled
                      ? Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent)
                      : Theme.colors.outline

        Behavior on color {
            ColorAnimation { duration: Md3.motion.short3; easing.type: Easing.OutCubic }
        }
    }

    // --- 状态层（圆形，居中于圆点，直径 = 轨道高，不越界）--------------------
    Rectangle {
        id: stateLayer
        width: Md3.size.switchTrackHeight
        height: Md3.size.switchTrackHeight
        radius: width / 2
        x: control.thumbCenter - width / 2
        y: (control.height - height) / 2
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

    // --- 焦点环 -------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Md3.space.xs
        radius: height / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.colors.primary
        opacity: control.activeFocus ? 0.9 : 0
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2 }
        }
    }

    // --- 圆点 ---------------------------------------------------------------
    Rectangle {
        id: thumb
        width: control.thumbSize
        height: control.thumbSize
        radius: width / 2
        x: control.thumbCenter - width / 2
        y: (control.height - height) / 2
        color: !control.enabled ? control.disabledThumbColor : control.thumbColor

        Behavior on width {
            NumberAnimation { duration: Md3.motion.short4; easing.type: Easing.InOutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: Md3.motion.short3; easing.type: Easing.OutCubic }
        }

        MdIcon {
            anchors.centerIn: parent
            name: "check"
            size: 16
            color: !control.enabled ? Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent)
                                    : Theme.colors.onPrimary
            opacity: control.checked && control.enabled ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Md3.motion.short3; easing.type: Easing.OutCubic }
            }
        }
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
