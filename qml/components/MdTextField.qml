import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 文本输入框：filled（默认，surfaceContainerHighest 容器）与 outlined（1dp 描边）。
 *
 * 规范要点：高度 56dp、圆角 4dp、bodyLarge 输入文字、浮动标签 bodySmall、
 * 聚焦时描边 2dp 并用 primary；错误态用 error 并把 supportingText 染成 error。
 *
 * 实现说明：Qt 6.10 的 TextField 不允许覆写 contentItem（运行时报
 * "Cannot assign to non-existent property contentItem"），因此这里用 FocusScope + TextInput
 * 自己拼装，API 与 TextField 的常用子集保持一致（text / readOnly / echoMode / validator）。
 *
 * 用法：
 *   MdTextField { label: "game.exe"; text: cfg.value; onEditingFinished: save() }
 */
FocusScope {
    id: control

    property alias text: input.text
    property string label: ""
    property string placeholderText: ""
    property string supportingText: ""
    property bool error: false
    property string variant: "filled"        // filled | outlined
    property string leadingIcon: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool monospace: false
    property bool compact: false
    property alias readOnly: input.readOnly
    property alias echoMode: input.echoMode
    property alias validator: input.validator
    property alias inputMethodHints: input.inputMethodHints
    property alias selectByMouse: input.selectByMouse
    property alias inputActiveFocus: input.activeFocus

    readonly property real fieldHeight: control.compact ? 48 : Md3.size.textField
    readonly property real supportingHeight: control.supportingText.length > 0 ? 20 : 0
    readonly property bool floating: input.activeFocus
                                      || control.text.length > 0
                                      || input.preeditText.length > 0
    readonly property color accentColor: control.error ? Theme.colors.error : Theme.colors.primary
    readonly property real textLeft: control.leadingIcon.length > 0 ? 44 : 16
    readonly property real textRight: control.trailingIcon.length > 0 ? 44
                                       : (control.trailingText.length > 0 ? 44 : 16)

    signal accepted()
    signal editingFinished()
    signal textEdited(string text)
    signal trailingIconClicked()

    implicitHeight: control.fieldHeight + control.supportingHeight
    implicitWidth: 240
    activeFocusOnTab: true

    Rectangle {
        id: container
        width: control.width
        height: control.fieldHeight
        radius: Md3.shape.extraSmall
        color: control.variant === "filled"
               ? (control.enabled ? Theme.colors.surfaceContainerHighest
                                  : Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContainer))
               : "transparent"
        border.width: control.variant === "outlined" ? (input.activeFocus ? 2 : 1) : 0
        border.color: control.error ? Theme.colors.error
                      : (input.activeFocus ? Theme.colors.primary : Theme.colors.outline)

        Rectangle {
            visible: control.variant === "filled"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: input.activeFocus ? 2 : 1
            color: control.error ? Theme.colors.error
                                 : (input.activeFocus ? Theme.colors.primary
                                                      : Theme.colors.onSurfaceVariant)
            opacity: control.enabled ? 1 : Md3.state.disabledContent
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: control.readOnly ? Qt.ArrowCursor : Qt.IBeamCursor
            onClicked: input.forceActiveFocus()
        }
    }

    MdIcon {
        visible: control.leadingIcon.length > 0
        name: control.leadingIcon
        size: 20
        x: 14
        y: (control.fieldHeight - height) / 2
        color: control.error ? Theme.colors.error : Theme.colors.onSurfaceVariant
    }

    MdIcon {
        id: trailingIconItem
        visible: control.trailingIcon.length > 0
        name: control.trailingIcon
        size: 20
        x: control.width - width - 14
        y: (control.fieldHeight - height) / 2
        color: Theme.colors.onSurfaceVariant

        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            onClicked: control.trailingIconClicked()
        }
    }

    MdText {
        visible: control.trailingText.length > 0 && !trailingIconItem.visible
        role: "labelSmall"
        mono: true
        text: control.trailingText
        tone: "variant"
        x: control.width - width - 14
        y: (control.fieldHeight - height) / 2
    }

    MdText {
        visible: control.label.length > 0
        text: control.label
        role: control.floating ? "bodySmall" : "bodyLarge"
        color: control.error ? Theme.colors.error
                             : (input.activeFocus ? Theme.colors.primary
                                                  : Theme.colors.onSurfaceVariant)
        x: control.textLeft
        y: control.floating ? 5 : (control.fieldHeight - height) / 2
        elide: Text.ElideRight
        width: Math.max(0, Math.min(implicitWidth,
                                    control.width - control.textLeft - control.textRight))

        Behavior on y {
            NumberAnimation { duration: Md3.motion.short4; easing.type: Easing.OutCubic }
        }
    }

    MdText {
        visible: control.label.length === 0
                 && control.text.length === 0
                 && control.placeholderText.length > 0
        text: control.placeholderText
        role: "bodyLarge"
        color: Md3.alpha(Theme.colors.onSurfaceVariant, 0.7)
        x: control.textLeft
        y: (control.fieldHeight - height) / 2
        elide: Text.ElideRight
        width: Math.max(0, control.width - control.textLeft - control.textRight)
    }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: control.textLeft
        anchors.rightMargin: control.textRight
        y: control.floating ? 22 : (control.fieldHeight - height) / 2
        height: control.floating ? control.fieldHeight - 26 : implicitHeight
        verticalAlignment: TextInput.AlignVCenter
        color: control.enabled ? Theme.colors.onSurface
                               : Md3.alpha(Theme.colors.onSurface, Md3.state.disabledContent)
        selectionColor: Theme.colors.primary
        selectedTextColor: Theme.colors.onPrimary
        font.family: control.monospace ? App.monoFontFamily : App.uiFontFamily
        font.pixelSize: control.monospace ? 13 : Md3.type.bodyLarge.size
        font.letterSpacing: control.monospace ? 0 : Md3.type.bodyLarge.tracking
        selectByMouse: true
        clip: true
        renderType: Text.NativeRendering
        enabled: control.enabled
        Accessible.name: control.label.length > 0 ? control.label : control.placeholderText
        Accessible.description: control.supportingText

        onAccepted: control.accepted()
        onEditingFinished: control.editingFinished()
        onTextEdited: control.textEdited(text)
    }

    MdText {
        visible: control.supportingText.length > 0
        text: control.supportingText
        role: "bodySmall"
        color: control.error ? Theme.colors.error : Theme.colors.onSurfaceVariant
        x: 16
        y: control.fieldHeight + 2
        width: Math.max(0, control.width - 32)
        wrapMode: Text.WordWrap
        maximumLineCount: 1
        elide: Text.ElideRight
    }
}
