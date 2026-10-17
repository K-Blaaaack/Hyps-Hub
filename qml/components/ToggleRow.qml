import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 通用配置开关行：键名 / 说明 / 开关 / 恢复默认 */
Item {
    id: root

    property var config: null
    property string configKey: ""
    property string title: ""
    property string description: ""
    property string hint: ""

    implicitHeight: Math.max(58, row.implicitHeight + 16)

    function currentValue() {
        if (!root.config) {
            return "";
        }
        const values = root.config.values;
        if (!values || values[root.configKey] === undefined) {
            return "";
        }
        return String(values[root.configKey]);
    }

    function truthy(value) {
        const text = String(value).toLowerCase();
        return text === "true" || text === "1" || text === "yes" || text === "on"
                || text === "enabled";
    }

    property bool checked: truthy(currentValue())
    property bool keyPresent: config && config.values
                              && config.values[configKey] !== undefined

    ColumnLayout {
        id: row
        anchors.left: parent.left
        anchors.right: controls.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        RowLayout {
            spacing: 8
            Text {
                text: root.title
                color: Theme.colors.paper2
                font.family: App.uiFontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            MicroLabel {
                label: root.configKey
                color: Theme.colors.disabled
                microSize: 9
                tracking: 0.8
            }
        }

        Text {
            text: root.description
            color: Theme.colors.muted
            font.family: App.uiFontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: text.length > 0
        }

        Text {
            text: root.hint
            color: Theme.colors.warn
            font.family: App.uiFontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: text.length > 0
        }
    }

    RowLayout {
        id: controls
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        MicroLabel {
            label: root.keyPresent ? (root.checked ? "ON" : "OFF") : "DEFAULT"
            color: root.keyPresent ? (root.checked ? Theme.colors.signal : Theme.colors.muted)
                                   : Theme.colors.disabled
            microSize: 9
            tracking: 1.2
        }

        ArkButton {
            text: "默认"
            visible: root.keyPresent
            implicitHeight: 34
            ghost: true
            font.pixelSize: 10
            onClicked: {
                if (root.config) {
                    root.config.removeKey(root.configKey);
                }
            }
        }

        ToggleSwitch {
            checked: root.checked
            onToggled: function (value) {
                if (root.config) {
                    root.config.setValue(root.configKey, value ? "true" : "false");
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.colors.rule
        opacity: 0.7
    }
}
