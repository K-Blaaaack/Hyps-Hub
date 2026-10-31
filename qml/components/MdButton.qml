import QtQuick
import QtQuick.Templates as T
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 按钮：filled / tonal / outlined / text / elevated 五种变体。
 *
 * 规范要点：高度 40dp、胶囊圆角（shape.full）、labelLarge 字号、
 * 状态层 hover 8% / pressed 10%、图标 18dp 与文字间距 8dp。
 * filled 用 primary/onPrimary；tonal 用 secondaryContainer/onSecondaryContainer；
 * outlined 用 1dp outline 描边 + primary 文字；elevated 用 surfaceContainerLow + 阴影。
 *
 * 用法：MdButton { text: "保存"; variant: "filled"; onClicked: save() }
 */
T.Button {
    id: control

    property string variant: "filled"   // filled | tonal | outlined | text | elevated
    property string iconName: ""
    property bool danger: false

    implicitHeight: Md3.size.button
    implicitWidth: Math.max(64, (contentItem ? contentItem.implicitWidth : 0)
                               + leftPadding + rightPadding)
    leftPadding: control.iconName.length > 0 ? 16 : 24
    rightPadding: control.iconName.length > 0 ? 20 : 24
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.role: Accessible.Button
    Accessible.name: control.text

    readonly property bool filledLike: control.variant === "filled"
                                       || control.variant === "tonal"
                                       || control.variant === "elevated"

    readonly property color containerColor: {
        if (control.danger) {
            return control.filledLike ? Theme.colors.error : "transparent";
        }
        switch (control.variant) {
        case "tonal":
            return Theme.colors.secondaryContainer;
        case "elevated":
            return Theme.colors.surfaceContainerLow;
        case "filled":
            return Theme.colors.primary;
        default:
            return "transparent";
        }
    }

    readonly property color contentColor: {
        if (!control.enabled) {
            return Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent);
        }
        if (control.danger) {
            return control.filledLike ? Theme.colors.onError : Theme.colors.error;
        }
        switch (control.variant) {
        case "tonal":
            return Theme.colors.onSecondaryContainer;
        case "filled":
            return Theme.colors.onPrimary;
        default:
            return Theme.colors.primary;
        }
    }

    readonly property color stateColor: {
        if (control.variant === "filled" && !control.danger) {
            return Theme.colors.onPrimary;
        }
        if (control.variant === "tonal") {
            return Theme.colors.onSecondaryContainer;
        }
        return control.danger ? Theme.colors.error : Theme.colors.primary;
    }

    contentItem: Item {
        implicitWidth: buttonRow.implicitWidth
        implicitHeight: buttonRow.implicitHeight

        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 8

            MdIcon {
                visible: control.iconName.length > 0
                name: control.iconName
                size: 18
                color: control.contentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            MdText {
                role: "labelLarge"
                text: control.text
                color: control.contentColor
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    background: Item {
        // elevated 的阴影近似（软件渲染下不用 shader 阴影）
        Rectangle {
            visible: control.variant === "elevated" && control.enabled
            anchors.fill: parent
            anchors.topMargin: 2
            radius: height / 2
            color: Md3.alpha(Theme.colors.shadow, 0.18)
            z: -1
        }

        Rectangle {
            id: container
            anchors.fill: parent
            radius: height / 2
            color: control.enabled ? control.containerColor
                                   : Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContainer)
            border.width: control.variant === "outlined" ? 1 : 0
            border.color: !control.enabled
                          ? Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContainer)
                          : (control.danger ? Theme.colors.error : Theme.colors.outline)

            // 状态层（hover / pressed）
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: control.stateColor
                opacity: !control.enabled ? 0
                         : (control.down ? Md3.state.pressed
                                         : (control.hovered ? Md3.state.hover : 0))
                Behavior on opacity {
                    NumberAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
                }
            }

            // 涟漪：按下扩散并淡出
            Rectangle {
                id: ripple
                property real centerX: control.pressX
                property real centerY: control.pressY

                width: 0
                height: 0
                radius: width / 2
                x: centerX - width / 2
                y: centerY - height / 2
                color: control.stateColor
                opacity: 0
                visible: width > 0
            }

            // 焦点指示环
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: height / 2
                color: "transparent"
                border.width: 2
                border.color: control.stateColor
                opacity: control.activeFocus ? 0.9 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Md3.motion.short2 }
                }
            }
        }
    }

    ParallelAnimation {
        id: rippleAnim
        NumberAnimation {
            target: ripple
            property: "width"
            to: control.height * 2.4
            duration: Md3.motion.medium2
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: ripple
            property: "height"
            to: control.height * 2.4
            duration: Md3.motion.medium2
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            from: 0.16
            to: 0
            duration: Md3.motion.medium3
            easing.type: Easing.OutCubic
        }
    }

    onPressedChanged: {
        if (pressed) {
            ripple.width = 0;
            ripple.height = 0;
            ripple.opacity = 0.16;
            rippleAnim.restart();
        }
    }
}
