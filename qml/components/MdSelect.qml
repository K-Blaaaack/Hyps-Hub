import QtQuick
import QtQuick.Controls
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 下拉选择：外观同 outlined 输入框，点击展开 MdMenu。 */
Item {
    id: root

    property string label: ""
    property var model: []
    property string currentValue: ""
    property string supportingText: ""
    property string placeholder: ""
    property bool compact: false

    signal activated(string value)

    readonly property real fieldHeight: root.compact ? 48 : Md3.size.textField
    readonly property real supportingHeight: root.supportingText.length > 0 ? 20 : 0
    readonly property bool hasValue: root.currentValue.length > 0

    function optionValue(option) {
        if (option === undefined || option === null) {
            return "";
        }
        if (typeof option === "object") {
            return option.value !== undefined ? String(option.value) : String(option.text);
        }
        return String(option);
    }

    function optionText(option) {
        if (option !== undefined && option !== null && typeof option === "object") {
            return String(option.text !== undefined ? option.text : option.value);
        }
        return String(option);
    }

    function labelForValue(value) {
        const list = root.model || [];
        for (let i = 0; i < list.length; ++i) {
            if (root.optionValue(list[i]) === value) {
                return root.optionText(list[i]);
            }
        }
        return value;
    }

    implicitHeight: root.fieldHeight + root.supportingHeight
    implicitWidth: 240
    activeFocusOnTab: true
    Accessible.role: Accessible.ComboBox
    Accessible.name: root.label
    Accessible.description: root.currentValue

    Keys.onSpacePressed: menu.opened ? menu.close() : menu.open()
    Keys.onDownPressed: menu.opened ? menu.close() : menu.open()

    Rectangle {
        id: container
        width: parent.width
        height: root.fieldHeight
        radius: Md3.shape.extraSmall
        color: "transparent"
        border.width: menu.opened || root.activeFocus ? 2 : 1
        border.color: menu.opened || root.activeFocus ? Theme.colors.primary : Theme.colors.outline

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.forceActiveFocus();
                menu.opened ? menu.close() : menu.open();
            }
        }
    }

    MdText {
        text: root.label
        role: root.hasValue || menu.opened ? "bodySmall" : "bodyLarge"
        color: menu.opened || root.activeFocus ? Theme.colors.primary
                                               : Theme.colors.onSurfaceVariant
        x: 16
        y: root.hasValue || menu.opened ? 5 : (root.fieldHeight - height) / 2
        elide: Text.ElideRight
        width: Math.max(0, root.width - 56)
    }

    MdText {
        visible: root.hasValue
        text: root.labelForValue(root.currentValue)
        role: "bodyLarge"
        color: Theme.colors.onSurface
        x: 16
        y: 22
        width: Math.max(0, root.width - 56)
        elide: Text.ElideRight
    }

    MdText {
        visible: !root.hasValue && !menu.opened && root.placeholder.length > 0
        text: root.placeholder
        role: "bodyLarge"
        color: Md3.alpha(Theme.colors.onSurfaceVariant, 0.7)
        x: 16
        y: (root.fieldHeight - height) / 2
        width: Math.max(0, root.width - 56)
        elide: Text.ElideRight
    }

    MdIcon {
        name: "chevron-down"
        size: 22
        color: Theme.colors.onSurfaceVariant
        x: root.width - width - 14
        y: (root.fieldHeight - height) / 2
        rotation: menu.opened ? 180 : 0
        Behavior on rotation {
            NumberAnimation { duration: Md3.motion.short3; easing.type: Easing.OutCubic }
        }
    }

    MdText {
        visible: root.supportingText.length > 0
        text: root.supportingText
        role: "bodySmall"
        tone: "variant"
        x: 16
        y: root.fieldHeight + 2
        width: Math.max(0, root.width - 32)
        elide: Text.ElideRight
    }

    MdMenu {
        id: menu
        width: root.width
        maxHeight: 320
        x: 0
        y: root.fieldHeight + 4

        Repeater {
            model: root.model
            delegate: MdMenuItem {
                width: menu.width - menu.padding * 2
                text: root.optionText(modelData)
                iconName: root.currentValue === root.optionValue(modelData) ? "check" : ""
                onTriggered: root.activated(root.optionValue(modelData))
            }
        }
    }
}
