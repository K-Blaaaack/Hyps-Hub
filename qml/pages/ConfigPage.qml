import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 配置页：通用配置（按分组折叠）+ 运行器配置 + 校验 + 原始编辑器。 */
Item {
    id: page

    property var host
    property string currentRunner: ""
    property var fieldGroups: []
    property var runnerFieldGroups: []

    function collectGroups(fields) {
        const seen = [];
        const list = fields ? fields : [];
        for (let i = 0; i < list.length; ++i) {
            const group = list[i].group !== undefined && list[i].group !== null
                    ? String(list[i].group) : "其它";
            if (seen.indexOf(group) < 0) {
                seen.push(group);
            }
        }
        return seen;
    }

    function fieldsIn(fields, group) {
        const list = fields ? fields : [];
        const out = [];
        for (let i = 0; i < list.length; ++i) {
            const name = list[i].group !== undefined && list[i].group !== null
                    ? String(list[i].group) : "其它";
            if (name === group) {
                out.push(list[i]);
            }
        }
        return out;
    }

    function refreshGroups() {
        page.fieldGroups = page.collectGroups(Configs.commonFields);
        page.runnerFieldGroups = page.collectGroups(Configs.runnerConfigFields
                                                   ? Configs.runnerConfigFields : []);
    }

    function activeRunner() {
        if (page.currentRunner.length > 0) {
            return page.currentRunner;
        }
        return Configs.runnerNames.length > 0 ? Configs.runnerNames[0] : "";
    }

    function runnerConfig() {
        const name = page.activeRunner();
        return name.length > 0 ? Configs.runnerConfig(name) : null;
    }

    function saveConfig(config) {
        if (!config) {
            return;
        }
        const result = config.save();
        if (result && result.ok) {
            if (page.host) {
                page.host.showToast(result.backup && result.backup.length > 0
                                    ? "已保存，备份：" + result.backup
                                    : (result.message ? result.message : "已保存"));
            }
        } else if (page.host) {
            page.host.showToast("保存失败：" + (result && result.error ? result.error : "未知错误"));
        }
    }

    Component.onCompleted: page.refreshGroups()

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight + Md3.space.xl * 2
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MdScrollBar { }

        ColumnLayout {
            id: content
            width: Math.min(1100, page.width - Md3.space.xl * 2)
            x: Md3.space.xl
            y: Md3.space.lg
            spacing: Md3.space.xl

            // 工具行
            MdCard {
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdIcon { name: "config"; size: 20; color: Theme.colors.primary }

                        MdText {
                            Layout.fillWidth: true
                            role: "bodySmall"
                            mono: true
                            tone: "variant"
                            text: Configs.commonConfigPath
                            elide: Text.ElideMiddle
                        }

                        MdTag {
                            visible: Configs.hasUnsavedChanges()
                            text: "未保存"
                            status: "warning"
                        }

                        MdIconButton {
                            iconName: "copy"
                            size: 32
                            iconSize: 16
                            tooltip: "复制路径"
                            onClicked: AppControl.copyToClipboard(Configs.commonConfigPath)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdButton {
                            text: "保存"
                            variant: "filled"
                            iconName: "save"
                            enabled: Configs.common !== null
                            onClicked: page.saveConfig(Configs.common)
                        }
                        MdButton {
                            text: "放弃修改"
                            variant: "tonal"
                            iconName: "refresh"
                            enabled: Configs.hasUnsavedChanges()
                            onClicked: if (Configs.common) Configs.common.discardChanges()
                        }
                        MdButton {
                            text: "从磁盘重载"
                            variant: "outlined"
                            iconName: "download"
                            onClicked: {
                                Configs.reloadAll();
                                page.refreshGroups();
                            }
                        }
                        MdButton {
                            text: "原始编辑器"
                            variant: "outlined"
                            iconName: "code"
                            visible: Settings.advancedMode
                            enabled: Configs.common !== null
                            onClicked: rawDialog.openWith(Configs.common ? Configs.common.text : "")
                        }
                        Item { Layout.fillWidth: true }
                    }

                    MdText {
                        Layout.fillWidth: true
                        role: "bodySmall"
                        tone: "variant"
                        text: "保存时会在同目录生成 .bak.<时间戳> 备份；删除某个键即回到上游默认行为。"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // 校验
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"
                visible: Configs.common !== null

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.sm

                    MdSectionHeader {
                        title: "校验"
                        caption: "有错误时无法保存"
                    }

                    MdValidationList {
                        Layout.fillWidth: true
                        issues: Configs.common ? Configs.validateCommon() : []
                        emptyText: "通用配置没有发现问题"
                    }
                }
            }

            // 通用配置
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"
                visible: Configs.common !== null

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.md

                    MdSectionHeader {
                        title: "通用配置"
                        caption: Configs.commonFields.length + " 个字段"
                    }

                    Repeater {
                        model: page.fieldGroups

                        delegate: MdExpansionPanel {
                            Layout.fillWidth: true
                            title: modelData
                            subtitle: page.fieldsIn(Configs.commonFields, modelData).length + " 项"
                            expanded: index < 2

                            Column {
                                width: parent.width
                                spacing: Md3.space.md

                                Repeater {
                                    model: page.fieldsIn(Configs.commonFields, modelData)

                                    delegate: Column {
                                        width: parent.width
                                        spacing: Md3.space.md

                                        MdField {
                                            width: parent.width
                                            config: Configs.common
                                            configKey: modelData.key
                                            title: modelData.title
                                            description: modelData.description
                                            hint: modelData.hint
                                            type: modelData.type
                                            options: modelData.options ? modelData.options : []
                                        }

                                        MdDivider {
                                            width: parent.width
                                            visible: index < parent.children.length - 2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 运行器
            MdCard {
                Layout.fillWidth: true
                variant: "outlined"
                visible: Configs.runnerNames.length > 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Md3.space.md

                    MdSectionHeader {
                        title: "运行器"
                        caption: Configs.runnerDirectory
                    }

                    MdBanner {
                        Layout.fillWidth: true
                        visible: Configs.runnerDirectoryIsolated
                        status: "info"
                        text: "运行器目录来自组件内部，只读。要自定义运行器，请把配置放到用户配置目录下的 runners/。"
                    }

                    MdSelect {
                        Layout.fillWidth: true
                        label: "选择运行器"
                        model: Configs.runnerNames
                        currentValue: page.activeRunner()
                        placeholder: "未选择"
                        onActivated: function (value) {
                            page.currentRunner = value;
                        }
                    }

                    MdValidationList {
                        Layout.fillWidth: true
                        issues: page.activeRunner().length > 0
                                ? Configs.validateRunner(page.activeRunner()) : []
                        emptyText: "该运行器没有发现问题"
                    }

                    Repeater {
                        model: page.runnerConfig() ? page.runnerConfig().keys() : []

                        delegate: MdField {
                            Layout.fillWidth: true
                            config: page.runnerConfig()
                            configKey: modelData
                            title: modelData
                            type: "text"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100000
                        spacing: Md3.space.sm

                        MdButton {
                            text: "保存运行器"
                            variant: "filled"
                            iconName: "save"
                            enabled: !Configs.runnerDirectoryIsolated
                            onClicked: page.saveConfig(page.runnerConfig())
                        }
                        MdButton {
                            text: "重载运行器"
                            variant: "outlined"
                            iconName: "refresh"
                            onClicked: Configs.reloadRunners()
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // 未初始化
            MdEmptyState {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                visible: Configs.common === null
                iconName: "config"
                title: "还没有配置文件"
                description: "通用配置文件不存在。初始化会创建一份带注释的默认配置。"
                actionText: "初始化配置"
                onActionClicked: Adapter.initializeConfig()
            }
        }
    }

    MdRawEditorDialog {
        id: rawDialog
        heading: "原始配置"
        subtitle: Configs.commonConfigPath
        onApplyText: function (text) { if (Configs.common) Configs.common.applyRawText(text) }
        onApplyAndSave: function (text) {
            if (Configs.common) {
                Configs.common.applyRawText(text);
                page.saveConfig(Configs.common);
            }
        }
    }
}
