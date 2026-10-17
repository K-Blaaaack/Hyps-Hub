import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/* 通用配置字段：bool / text / int / array / file / dir / runner */
Item {
    id: root

    property var config: null
    property string configKey: ""
    property string title: ""
    property string description: ""
    property string hint: ""
    property string type: "text"
    property var options: []

    implicitHeight: content.implicitHeight

    function value() {
        if (!root.config) {
            return "";
        }
        const values = root.config.values;
        return values && values[root.configKey] !== undefined ? String(values[root.configKey]) : "";
    }

    function truthy(text) {
        const lower = String(text).toLowerCase();
        return lower === "true" || lower === "1" || lower === "yes" || lower === "on"
                || lower === "enabled";
    }

    function keyPresent() {
        return root.config && root.config.values
                && root.config.values[root.configKey] !== undefined;
    }

    function arrayText() {
        if (!root.config) {
            return "";
        }
        return root.config.arrayValues(root.configKey).join("\n");
    }

    function setValue(value) {
        if (root.config) {
            root.config.setValue(root.configKey, value);
        }
    }

    function setArray() {
        if (!root.config) {
            return;
        }
        const lines = arrayArea.text.split("\n");
        const values = [];
        for (let i = 0; i < lines.length; ++i) {
            const trimmed = lines[i].trim();
            if (trimmed.length > 0 && trimmed.charAt(0) !== "#") {
                values.push(trimmed);
            }
        }
        root.config.setArray(root.configKey, values);
    }

    function syncEditors() {
        if (!textInput.activeFocus) {
            textInput.text = root.value();
        }
        if (!arrayArea.activeFocus) {
            arrayArea.text = root.arrayText();
        }
    }

    Component.onCompleted: syncEditors()

    Connections {
        target: root.config
        function onChanged() { root.syncEditors(); }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
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

            Item { Layout.fillWidth: true }

            ArkButton {
                text: "默认"
                visible: root.keyPresent()
                implicitHeight: 26
                ghost: true
                font.pixelSize: 9
                onClicked: if (root.config) root.config.removeKey(root.configKey)
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.description
            color: Theme.colors.muted
            font.family: App.uiFontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.hint
            color: Theme.colors.warn
            font.family: App.uiFontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.type === "bool"

            MicroLabel {
                label: root.keyPresent() ? (root.truthy(root.value()) ? "ON" : "OFF") : "DEFAULT"
                color: root.truthy(root.value()) ? Theme.colors.signal : Theme.colors.muted
                microSize: 9
                tracking: 1.2
            }

            ToggleSwitch {
                checked: root.truthy(root.value())
                onToggled: function (value) { root.setValue(value ? "true" : "false") }
            }
        }

        TextField {
            id: textInput
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            visible: root.type === "text" || root.type === "int"
            color: Theme.colors.paper2
            font.family: App.monoFontFamily
            font.pixelSize: 12
            leftPadding: 10
            selectByMouse: true
            placeholderText: root.type === "int" ? "整数" : ""
            placeholderTextColor: Theme.colors.disabled
            onEditingFinished: root.setValue(text)

            background: Rectangle {
                color: Theme.colors.ink
                border.width: 1
                border.color: textInput.activeFocus ? Theme.colors.signal : Theme.colors.line
            }
        }

        PathField {
            Layout.fillWidth: true
            visible: root.type === "file" || root.type === "dir"
            value: root.value()
            mode: root.type === "dir" ? "dir" : "file"
            nameFilter: root.type === "file" ? "*.exe *.bat *.cmd *.sh *.x86_64" : "*"
            dialogTitle: root.title
            onCommitted: function (path) { root.setValue(path) }
        }

        ComboBox {
            id: runnerInput
            Layout.preferredWidth: 260
            Layout.preferredHeight: 34
            visible: root.type === "runner"
            model: root.options
            currentIndex: Math.max(-1, root.options.indexOf(root.value()))
            font.family: App.monoFontFamily
            font.pixelSize: 12
            onActivated: root.setValue(currentText)

            background: Rectangle {
                color: Theme.colors.ink
                border.width: 1
                border.color: runnerInput.activeFocus || runnerInput.popup.visible
                              ? Theme.colors.signal : Theme.colors.line
            }

            contentItem: Text {
                leftPadding: 10
                text: runnerInput.displayText.length > 0 ? runnerInput.displayText : "（未设置）"
                color: Theme.colors.paper2
                font: runnerInput.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: MicroLabel {
                x: runnerInput.width - width - 10
                y: (runnerInput.height - height) / 2
                label: "V"
                color: Theme.colors.muted
                microSize: 9
                tracking: 0.8
            }

            popup: Popup {
                y: runnerInput.height
                width: runnerInput.width
                padding: 1

                background: Rectangle {
                    color: Theme.colors.ink2
                    border.width: 1
                    border.color: Theme.colors.lineHover
                }

                contentItem: ListView {
                    implicitHeight: Math.min(contentHeight, 220)
                    model: runnerInput.delegateModel
                    clip: true
                }
            }

            delegate: ItemDelegate {
                width: runnerInput.width
                height: 32
                text: modelData
                font.family: App.monoFontFamily
                font.pixelSize: 12
                highlighted: runnerInput.highlightedIndex === index

                background: Rectangle {
                    color: parent.highlighted ? Theme.colors.ink3 : "transparent"
                    Rectangle {
                        width: 2
                        height: parent.height
                        color: parent.parent.highlighted ? Theme.colors.signal : "transparent"
                    }
                }

                contentItem: Text {
                    leftPadding: 10
                    text: parent.text
                    color: Theme.colors.paper2
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.type === "array"

            TextArea {
                id: arrayArea
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                color: Theme.colors.paper2
                font.family: App.monoFontFamily
                font.pixelSize: 12
                leftPadding: 10
                topPadding: 8
                selectByMouse: true
                wrapMode: TextArea.WrapAnywhere
                placeholderText: "每行一个数组元素"
                placeholderTextColor: Theme.colors.disabled
                background: Rectangle {
                    color: Theme.colors.ink
                    border.width: 1
                    border.color: arrayArea.activeFocus ? Theme.colors.signal : Theme.colors.line
                }
            }

            RowLayout {
                spacing: 10

                ArkButton {
                    text: "应用参数"
                    implicitHeight: 34
                    onClicked: root.setArray()
                }

                MicroLabel {
                    label: "ARRAY / 每行一个元素"
                    color: Theme.colors.disabled
                    microSize: 8
                    tracking: 1.0
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
