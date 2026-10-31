import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HypsHub 1.0
import "../components"
import "../theme/Md3.js" as Md3

/* 游戏页：左栏游戏列表 + 右栏配置编辑与启动。 */
Item {
    id: page

    property var host
    property string currentSlug: ""
    property string activeSlug: ""
    property var fieldGroups: []

    // 模型是异步扫描的；用命令式同步，避免把 Games.count 放进绑定（会与刷新信号互相触发）
    function syncActiveSlug() {
        const next = page.activeSlug.length > 0
                ? page.currentSlug
                : (Games.count > 0 ? Games.firstSlug() : "");
        if (next !== page.activeSlug) {
            page.activeSlug = next;
            page.refreshGroups();
        }
    }

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

    function refreshGroups() {
        page.fieldGroups = page.collectGroups(
            page.activeSlug.length > 0 ? Configs.gameFieldsFor(page.activeSlug) : []);
    }

    function fieldsIn(group) {
        const list = page.activeSlug.length > 0 ? Configs.gameFieldsFor(page.activeSlug) : [];
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

    function gameConfig() {
        return page.activeSlug.length > 0 ? Configs.gameConfig(page.activeSlug) : null;
    }

    function gameInfo() {
        return page.activeSlug.length > 0 ? Games.gameBySlug(page.activeSlug) : ({});
    }

    function select(slug) {
        page.currentSlug = slug;
    }

    function saveGame() {
        const config = page.gameConfig();
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

    function launch() {
        const info = page.gameInfo();
        const guard = Adapter.canLaunch(page.activeSlug);
        if (guard && guard.ok === false) {
            if (page.host) {
                page.host.showToast(guard.reason ? guard.reason : "当前无法启动");
            }
            return;
        }
        Adapter.launchGame(page.activeSlug, info.label ? info.label : page.activeSlug);
        if (page.host) {
            page.host.navigate("tasks");
        }
    }

    Component.onCompleted: page.syncActiveSlug()
    onCurrentSlugChanged: page.syncActiveSlug()

    Connections {
        target: Games
        function onChanged() { page.syncActiveSlug() }
    }

    RowLayout {
        anchors.fill: parent
        // 和单栏页统一：左右 24、上 16，切页时左边缘不跳
        anchors.margins: Md3.space.xl
        anchors.topMargin: Md3.space.lg
        spacing: Md3.space.lg

        // 左：游戏列表（标题栏放进面板内，左右两栏顶边才对得齐）
        Rectangle {
            Layout.preferredWidth: 300
            Layout.minimumWidth: 300
            Layout.maximumWidth: 300
            Layout.fillHeight: true
            radius: Md3.shape.medium
            color: Theme.colors.surfaceContainerLow
            border.width: 1
            border.color: Theme.colors.outlineVariant
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Md3.space.sm
                spacing: Md3.space.sm

                RowLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 100000
                    Layout.leftMargin: 8
                    Layout.rightMargin: 4
                    spacing: Md3.space.sm

                    MdText { role: "titleSmall"; text: "游戏" }
                    MdTag {
                        text: Games.count + ""
                        status: "neutral"
                    }
                    Item { Layout.fillWidth: true }
                    MdIconButton {
                        iconName: "add"
                        size: 32
                        iconSize: 18
                        tooltip: "添加游戏"
                        onClicked: addDialog.open()
                    }
                }

                ListView {
                    id: gameList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Games
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: MdScrollBar { }

                    delegate: Item {
                        width: gameList.width
                        height: 64

                        readonly property bool selected: page.activeSlug === model.slug

                        Rectangle {
                            anchors.fill: parent
                            radius: Md3.shape.small
                            color: selected ? Theme.colors.secondaryContainer
                                 : (rowHover.containsMouse ? Md3.hover(Theme.colors.onSurface)
                                                           : "transparent")
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            MdText {
                                width: parent.width
                                role: "bodyLarge"
                                text: model.label
                                color: selected ? Theme.colors.onSecondaryContainer
                                                : Theme.colors.onSurface
                                elide: Text.ElideRight
                            }

                            MdText {
                                width: parent.width
                                role: "bodySmall"
                                text: model.status
                                color: model.statusLevel === "error" ? Theme.colors.error
                                     : (model.statusLevel === "warning" ? Theme.colors.warning
                                                                        : Theme.colors.onSurfaceVariant)
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: !model.launchable
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.colors.outline
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.select(model.slug)
                        }
                    }

                    MdText {
                        anchors.centerIn: parent
                        visible: gameList.count === 0
                        role: "bodySmall"
                        tone: "variant"
                        text: "还没有游戏配置"
                    }
                }
            }
        }

        // 右：编辑区
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MdEmptyState {
                anchors.centerIn: parent
                width: parent.width - Md3.space.xl * 2
                visible: page.activeSlug.length === 0
                iconName: "games"
                title: "选择一个游戏"
                description: "从左侧选择已配置的游戏，或用「添加游戏」创建一份新配置。"
                actionText: "添加游戏"
                onActionClicked: addDialog.open()
            }

            Flickable {
                anchors.fill: parent
                visible: page.activeSlug.length > 0
                clip: true
                contentWidth: width
                contentHeight: editor.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: MdScrollBar { }

                ColumnLayout {
                    id: editor
                    width: parent.width - Md3.space.sm
                    // 页面级卡片堆叠统一 24（诊断/设置/关于页都是 24）
                    spacing: Md3.space.xl

                    // 头部
                    MdCard {
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.sm

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100000
                                spacing: Md3.space.sm

                                MdText {
                                    Layout.fillWidth: true
                                    role: "titleLarge"
                                    text: page.gameInfo().label ? page.gameInfo().label : page.activeSlug
                                    elide: Text.ElideRight
                                }

                                MdTag {
                                    text: page.gameInfo().status ? page.gameInfo().status : "未知"
                                    status: page.gameInfo().statusLevel === "error" ? "error"
                                          : (page.gameInfo().statusLevel === "warning" ? "warning"
                                                                                       : "success")
                                }

                                MdTag {
                                    visible: !page.gameInfo().exeExists
                                    text: "exe 缺失"
                                    status: "error"
                                }

                                MdTag {
                                    visible: Configs.hasUnsavedChanges()
                                    text: "未保存"
                                    status: "warning"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100000
                                spacing: Md3.space.sm

                                // 弹簧放在行首，动作按钮才会靠右对齐
                                Item { Layout.fillWidth: true }

                                MdButton {
                                    text: "启动"
                                    variant: "filled"
                                    iconName: "play"
                                    enabled: page.gameInfo().launchable === true
                                    onClicked: page.launch()
                                }
                                MdButton {
                                    text: "保存"
                                    variant: "tonal"
                                    iconName: "save"
                                    enabled: Configs.hasUnsavedChanges()
                                    onClicked: page.saveGame()
                                }
                                MdButton {
                                    text: "放弃修改"
                                    variant: "outlined"
                                    enabled: Configs.hasUnsavedChanges()
                                    onClicked: {
                                        const config = page.gameConfig();
                                        if (config) {
                                            config.discardChanges();
                                        }
                                    }
                                }
                                MdButton {
                                    text: "重载"
                                    variant: "outlined"
                                    iconName: "download"
                                    onClicked: {
                                        const config = page.gameConfig();
                                        if (config) {
                                            config.reload();
                                        }
                                    }
                                }
                                MdButton {
                                    text: "原始编辑器"
                                    variant: "outlined"
                                    iconName: "code"
                                    visible: Settings.advancedMode
                                    onClicked: {
                                        const config = page.gameConfig();
                                        if (config) {
                                            rawDialog.openWith(config.text);
                                        }
                                    }
                                }
                            }

                            MdText {
                                Layout.fillWidth: true
                                visible: !page.gameInfo().launchable
                                role: "bodySmall"
                                color: Theme.colors.warning
                                wrapMode: Text.WordWrap
                                text: "暂时无法启动：" + (page.gameInfo().status ? page.gameInfo().status : "配置不完整")
                            }
                        }
                    }

                    // 校验
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.sm

                            MdSectionHeader {
                                title: "校验"
                                caption: "有错误时无法启动"
                            }

                            MdValidationList {
                                Layout.fillWidth: true
                                issues: page.activeSlug.length > 0 ? Configs.validateGame(page.activeSlug) : []
                                emptyText: "这份配置没有发现问题"
                            }
                        }
                    }

                    // 字段
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.md

                            MdSectionHeader {
                                title: "配置字段"
                                caption: page.activeSlug + ".conf"
                            }

                            Repeater {
                                model: page.fieldGroups

                                delegate: MdExpansionPanel {
                                    Layout.fillWidth: true
                                    title: modelData
                                    subtitle: page.fieldsIn(modelData).length + " 项"
                                    expanded: modelData === "基础" || index === 0

                                    Column {
                                        width: parent.width
                                        spacing: Md3.space.md

                                        Repeater {
                                            model: page.fieldsIn(modelData)

                                            delegate: Column {
                                                width: parent.width
                                                spacing: Md3.space.md

                                                MdField {
                                                    width: parent.width
                                                    config: page.gameConfig()
                                                    configKey: modelData.key
                                                    title: modelData.title
                                                    description: modelData.description
                                                    hint: modelData.hint
                                                    type: modelData.type
                                                    options: modelData.options ? modelData.options : []
                                                }

                                                MdDivider { width: parent.width }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 路径信息
                    MdCard {
                        Layout.fillWidth: true
                        variant: "outlined"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Md3.space.xs

                            MdSectionHeader {
                                title: "文件与启动"
                            }

                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "配置文件"
                                value: page.gameInfo().configPath ? page.gameInfo().configPath : "—"
                                mono: true
                                copyable: true
                                onCopyRequested: AppControl.copyToClipboard(page.gameInfo().configPath)
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "启动脚本"
                                value: page.gameInfo().launcherPath ? page.gameInfo().launcherPath : "—"
                                mono: true
                                copyable: true
                                onCopyRequested: AppControl.copyToClipboard(page.gameInfo().launcherPath)
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "可执行文件"
                                value: page.gameInfo().exePath ? page.gameInfo().exePath : "—"
                                mono: true
                                copyable: true
                                onCopyRequested: AppControl.copyToClipboard(page.gameInfo().exePath)
                            }
                            MdInfoRow {
                                Layout.fillWidth: true
                                label: "运行器"
                                value: page.gameInfo().runnerName ? page.gameInfo().runnerName : "未设置"
                                mono: true
                            }
                        }
                    }
                }
            }
        }
    }

    // 添加游戏
    Dialog {
        id: addDialog
        objectName: "addGameDialog"
        modal: true
        padding: 0
        anchors.centerIn: Overlay.overlay
        width: 520
        height: Math.min(520, page.height - 96)
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle { color: Md3.alpha(Theme.colors.scrim, 0.4) }

        background: Rectangle {
            radius: Md3.shape.large
            color: Theme.colors.surfaceContainerHigh
        }

        contentItem: ColumnLayout {
            spacing: Md3.space.md

            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                Layout.margins: Md3.space.lg
                Layout.bottomMargin: 0
                spacing: Md3.space.sm

                MdIcon {
                    name: "add"
                    size: 22
                    color: Theme.colors.primary
                    Layout.alignment: Qt.AlignTop
                }

                // 标题和说明放进同一列：分成两个同级项时，说明会退回图标那条左轨
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 100000
                    spacing: Md3.space.xs

                    MdText {
                        role: "titleLarge"
                        text: "添加游戏"
                    }

                    MdText {
                        Layout.fillWidth: true
                        role: "bodySmall"
                        tone: "variant"
                        text: "模板来自组件内的游戏定义；已配置的游戏会显示为「已存在」。"
                        wrapMode: Text.WordWrap
                    }
                }

                MdIconButton {
                    iconName: "close"
                    Layout.alignment: Qt.AlignTop
                    onClicked: addDialog.close()
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Md3.space.sm
                Layout.rightMargin: Md3.space.sm
                clip: true
                model: Games.templates
                spacing: 2
                ScrollBar.vertical: MdScrollBar { }

                delegate: MdListItem {
                    width: ListView.view.width
                    headline: modelData.label
                    supporting: modelData.slug + (modelData.configured ? " · 已存在" : "")
                    trailingText: modelData.configured ? "已存在" : "创建"
                    status: modelData.configured ? "success" : "neutral"
                    interactive: !modelData.configured
                    onClicked: {
                        Adapter.createGameConfig(modelData.slug);
                        page.select(modelData.slug);
                        addDialog.close();
                        if (page.host) {
                            page.host.showToast("已创建 " + modelData.label + " 配置");
                        }
                    }
                }
            }

            // 模板为空时不要留一大块空白
            MdEmptyState {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Games.templates.length === 0
                iconName: "games"
                containerColor: Theme.colors.surfaceContainerHighest
                title: "组件里还没有游戏定义"
                description: "先初始化上游组件，再回到这里添加游戏配置。"
            }

            // 底部操作区
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 100000
                Layout.margins: Md3.space.lg
                Layout.topMargin: 0
                spacing: Md3.space.sm

                Item { Layout.fillWidth: true }

                MdButton {
                    text: "关闭"
                    variant: "text"
                    onClicked: addDialog.close()
                }
            }
        }
    }

    MdRawEditorDialog {
        id: rawDialog
        objectName: "rawEditorDialog"
        heading: "原始配置"
        subtitle: page.activeSlug + ".conf"
        onApplyText: function (text) {
            const config = page.gameConfig();
            if (config) {
                config.applyRawText(text);
            }
        }
        onApplyAndSave: function (text) {
            const config = page.gameConfig();
            if (config) {
                config.applyRawText(text);
                page.saveGame();
            }
        }
    }
}
