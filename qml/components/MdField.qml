import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * 通用配置字段：bool / text / int / array / file / dir / runner / enum。
 * enum 的 options 支持 [{value,label}] 与纯字符串；value 为空串表示「删除该键」。
 */
Item {
    id: root
    Layout.fillWidth: true

    property var config: null
    property string configKey: ""
    property string title: ""
    property string description: ""
    property string hint: ""
    property string type: "text"
    property var options: []

    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth

    function value() {
        if (!root.config || !root.config.values) {
            return "";
        }
        const values = root.config.values;
        return values[root.configKey] !== undefined ? String(values[root.configKey]) : "";
    }

    function keyPresent() {
        return root.config && root.config.values
                && root.config.values[root.configKey] !== undefined;
    }

    function truthy(text) {
        const lower = String(text).toLowerCase();
        return lower === "true" || lower === "1" || lower === "yes"
                || lower === "on" || lower === "enabled";
    }

    function arrayText() {
        if (!root.config) {
            return "";
        }
        const values = root.config.arrayValues(root.configKey);
        return values ? values.join("\n") : "";
    }

    function setValue(next) {
        if (root.config) {
            root.config.setValue(root.configKey, next);
        }
    }

    function optionValue(option) {
        if (option === undefined || option === null) {
            return "";
        }
        if (typeof option === "object") {
            return option.value !== undefined && option.value !== null ? String(option.value) : "";
        }
        return String(option);
    }

    function optionLabel(option) {
        if (option === undefined || option === null) {
            return "";
        }
        if (typeof option === "object") {
            const label = option.label;
            return label !== undefined && label !== null && String(label).length > 0
                    ? String(label) : root.optionValue(option);
        }
        return String(option);
    }

    function optionList() {
        return root.options ? root.options : [];
    }

    function writeOption(option) {
        if (!root.config) {
            return;
        }
        const next = root.optionValue(option);
        if (next.length === 0) {
            if (root.keyPresent()) {
                root.config.removeKey(root.configKey);
            }
            return;
        }
        root.setValue(next);
    }

    function applyArray() {
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
        if (!arrayArea.activeFocus) {
            arrayArea.text = root.arrayText();
        }
    }

    Component.onCompleted: syncEditors()

    Connections {
        target: root.config
        ignoreUnknownSignals: true
        function onChanged() { root.syncEditors() }
    }

    ColumnLayout {
        id: content
        width: root.width
        spacing: Md3.space.sm

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            spacing: Md3.space.sm

            MdText {
                role: "titleSmall"
                text: root.title
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            MdText {
                role: "labelSmall"
                mono: true
                tone: "variant"
                text: root.configKey
                Layout.maximumWidth: 260
                elide: Text.ElideMiddle
            }

            // 没有默认值时按钮留位不显示：否则这一行的 key 文字会顶到最右，
            // 和上下有按钮的行错开一截（列看着是锯齿）
            MdButton {
                text: "恢复默认"
                variant: "text"
                opacity: root.keyPresent() ? 1 : 0
                enabled: root.keyPresent()
                implicitHeight: 32
                onClicked: if (root.config) root.config.removeKey(root.configKey)
            }
        }

        MdText {
            Layout.fillWidth: true
            visible: root.description.length > 0
            role: "bodySmall"
            tone: "variant"
            text: root.description
            wrapMode: Text.WordWrap
        }

        MdText {
            Layout.fillWidth: true
            visible: root.hint.length > 0
            role: "bodySmall"
            color: Theme.colors.warning
            text: root.hint
            wrapMode: Text.WordWrap
        }

        // bool
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            spacing: Md3.space.md
            visible: root.type === "bool"

            MdSwitch {
                checked: root.truthy(root.value())
                accessibleName: root.title
                onToggled: function (on) { root.setValue(on ? "true" : "false") }
            }

            MdText {
                role: "bodySmall"
                tone: "variant"
                text: root.keyPresent()
                      ? (root.truthy(root.value()) ? "已启用（写入 true）" : "已禁用（写入 false）")
                      : "未设置，使用上游默认值"
                Layout.fillWidth: true
            }
        }

        // enum
        Flow {
            Layout.fillWidth: true
            spacing: Md3.space.sm
            visible: root.type === "enum"

            Repeater {
                model: root.optionList()

                delegate: MdChip {
                    text: root.optionLabel(modelData)
                    variant: "filter"
                    selected: root.value() === root.optionValue(modelData)
                    onClicked: root.writeOption(modelData)
                }
            }
        }

        // text / int
        MdTextField {
            Layout.fillWidth: true
            visible: root.type === "text" || root.type === "int"
            monospace: true
            text: root.value()
            placeholderText: root.type === "int" ? "整数" : ""
            onEditingFinished: root.setValue(text)
        }

        // runner
        MdSelect {
            Layout.fillWidth: true
            visible: root.type === "runner"
            label: "运行器"
            model: root.optionList()
            currentValue: root.value()
            placeholder: "未设置"
            onActivated: function (value) { root.setValue(value) }
        }

        // file / dir
        MdPathField {
            Layout.fillWidth: true
            visible: root.type === "file" || root.type === "dir"
            text: root.value()
            mode: root.type === "dir" ? "dir" : "file"
            nameFilter: root.type === "file" ? "*.exe *.bat *.cmd *.sh *.x86_64" : "*"
            dialogTitle: root.title
            onCommitted: function (path) { root.setValue(path) }
        }

        // array
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            spacing: Md3.space.sm
            visible: root.type === "array"

            MdCodeField {
                id: arrayArea
                Layout.fillWidth: true
                minHeight: 140
                placeholderText: "每行一个元素，# 开头的行会被忽略"
            }

            RowLayout {
                spacing: Md3.space.sm
                Item { Layout.fillWidth: true }
                MdButton {
                    text: "应用参数"
                    variant: "tonal"
                    onClicked: root.applyArray()
                }
            }
        }
    }
}
