import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 游戏配置与启动：读取隔离 CONFIG_DIR，启动仍调用上游 scripts/<Game>.sh */
Item {
    id: page

    property var host
    property string selectedSlug: ""
    property string pendingSlug: ""
    property var gameInfo: ({})
    property var gameCfg: selectedSlug.length > 0 ? Configs.gameConfig(selectedSlug) : null
    property var issues: []
    property bool advanced: false

    function syncGameInfo() {
        gameInfo = selectedSlug.length > 0 ? Games.gameBySlug(selectedSlug) : ({});
    }

    function refreshIssues() {
        issues = selectedSlug.length > 0 ? Configs.validateGame(selectedSlug) : [];
    }

    function selectGame(slug) {
        if (slug === page.selectedSlug) {
            return;
        }
        page.selectedSlug = slug;
        page.syncGameInfo();
        page.refreshIssues();
    }

    function doSave() {
        if (!page.gameCfg) {
            return false;
        }
        const result = page.gameCfg.save();
        if (result.ok) {
            page.host.showToast(result.backup
                                ? "已保存，原文件备份为 " + result.backup
                                : "已保存");
            Games.refresh();
            page.refreshIssues();
            return true;
        }
        page.host.showToast("保存失败：" + result.error);
        return false;
    }

    function trySave() {
        if (!page.gameCfg) {
            return;
        }
        if (!page.gameCfg.dirty) {
            page.host.showToast("没有需要保存的修改");
            return;
        }
        if (page.issues.length > 0) {
            saveDialog.open();
        } else {
            page.doSave();
        }
    }

    function launch() {
        if (!page.gameCfg || page.gameCfg.dirty) {
            page.host.showToast("请先保存配置再启动");
            return;
        }
        const task = Adapter.launchGame(page.selectedSlug, page.gameInfo.label
                                                            ? page.gameInfo.label : page.selectedSlug);
        if (!task) {
            page.host.showToast("无法启动：" + Adapter.lastError);
            return;
        }
        Tasks.select(task.id);
        page.host.navigate("tasks");
    }

    function fieldsFor(group) {
        const all = Configs.gameFields;
        const result = [];
        for (let i = 0; i < all.length; ++i) {
            if (all[i].group === group) {
                result.push(all[i]);
            }
        }
        return result;
    }

    function stateKind(level) {
        if (level === "ok") return "state";
        if (level === "error") return "danger";
        return "warn";
    }

    Component.onCompleted: {
        page.selectedSlug = Games.firstSlug();
        page.syncGameInfo();
        page.refreshIssues();
    }

    onSelectedSlugChanged: {
        page.syncGameInfo();
        page.refreshIssues();
    }

    Connections {
        target: Games
        function onChanged() {
            if (page.selectedSlug.length === 0
                || Games.indexOfSlug(page.selectedSlug) < 0) {
                page.selectedSlug = Games.firstSlug();
            }
            page.syncGameInfo();
        }
    }

    Connections {
        target: page.gameCfg
        function onChanged() { page.refreshIssues(); }
    }

    Connections {
        target: Adapter
        function onGameConfigCreated(slug) {
            page.pendingSlug = slug;
            Games.refresh();
            Configs.reloadAll();
            page.selectedSlug = slug;
            page.host.showToast("已创建 " + slug + ".conf，请填写 game.exe 与 runner.name");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        PageHeader {
            Layout.fillWidth: true
            index: "02"
            title: "游戏"
            english: "GAMES"
            subtitle: "CONFIGURATION / LAUNCH / REAL OUTPUT"

            ArkButton {
                text: "添加游戏配置"
                implicitHeight: 40
                primary: true
                enabled: Runtime.ready
                onClicked: addDialog.open()
            }

            ArkButton {
                text: "重新扫描"
                implicitHeight: 40
                ghost: true
                onClicked: {
                    Games.refresh();
                    page.host.showToast("已重新扫描配置与启动脚本");
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // 左侧游戏列表
            ChamferedPanel {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                contentMargin: 14
                cut: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    SectionHeader {
                        Layout.fillWidth: true
                        index: "01"
                        english: "CONFIGURED"
                        title: "已配置游戏"
                    }

                    ListView {
                        id: gameList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: Games
                        spacing: 0
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Item {
                            width: gameList.width
                            height: 66

                            readonly property bool selected: page.selectedSlug === slug

                            Rectangle {
                                anchors.fill: parent
                                color: selected ? Theme.colors.ink3
                                       : (gameMouse.containsMouse ? Theme.colors.ink3 : "transparent")
                            }

                            Rectangle {
                                width: 2
                                height: parent.height
                                color: selected ? Theme.colors.signal : "transparent"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: label
                                        color: Theme.colors.paper2
                                        font.family: App.uiFontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: 7

                                        MicroLabel {
                                            label: slug
                                            color: Theme.colors.muted
                                            microSize: 9
                                            tracking: 0.8
                                        }

                                        MicroLabel {
                                            label: runnerName.length > 0 ? runnerName : "NO RUNNER"
                                            color: Theme.colors.disabled
                                            microSize: 9
                                            tracking: 0.6
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: status
                                        color: statusLevel === "ok" ? Theme.colors.state
                                             : (statusLevel === "error" ? Theme.colors.danger
                                                                        : Theme.colors.warn)
                                        font.family: App.uiFontFamily
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                ArkTag {
                                    text: statusLevel === "ok" ? "READY"
                                          : (statusLevel === "error" ? "ERROR" : "WARN")
                                    kind: page.stateKind(statusLevel)
                                    implicitHeight: 20
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.colors.rule
                                opacity: 0.6
                            }

                            MouseArea {
                                id: gameMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selectGame(slug)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Games.count === 0
                        text: "还没有游戏配置。点击「添加游戏配置」，从上游示例模板创建。"
                        color: Theme.colors.muted
                        font.family: App.uiFontFamily
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    MicroLabel {
                        Layout.fillWidth: true
                        label: "GAMES DIR: " + Games.gamesDirectory
                        color: Theme.colors.disabled
                        microSize: 8
                        tracking: 0.5
                        elide: Text.ElideMiddle
                    }
                }
            }

            // 右侧详情
            ChamferedPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentMargin: 16
                cut: 10

                Item {
                    anchors.fill: parent

                    EmptyState {
                        anchors.fill: parent
                        visible: page.selectedSlug.length === 0
                        title: "选择一个游戏，或添加配置"
                        description: "游戏列表来自 CONFIG_DIR/games；启动脚本通过 scripts/*.sh 中的 GAME_NAME 自动匹配。"
                        actionText: "添加游戏配置"
                        indexText: "02"
                        onActionTriggered: addDialog.open()
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        visible: page.selectedSlug.length > 0
                        spacing: 10

                        // 标题行
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: page.gameInfo.label ? page.gameInfo.label : page.selectedSlug
                                color: Theme.colors.paper
                                font.family: App.uiFontFamily
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                font.letterSpacing: -0.2
                            }

                            MicroLabel {
                                label: page.selectedSlug
                                color: Theme.colors.signal
                                microSize: 9
                                tracking: 1.2
                            }

                            ArkTag {
                                text: page.gameInfo.status ? page.gameInfo.status : ""
                                kind: page.stateKind(page.gameInfo.statusLevel)
                                implicitHeight: 18
                            }

                            Item { Layout.fillWidth: true }

                            ArkButton {
                                text: "重新加载"
                                implicitHeight: 40
                                ghost: true
                                onClicked: {
                                    if (page.gameCfg) {
                                        page.gameCfg.discardChanges();
                                        page.refreshIssues();
                                        page.host.showToast("已从磁盘重新加载");
                                    }
                                }
                            }

                            ArkButton {
                                text: "保存配置"
                                implicitHeight: 40
                                enabled: page.gameCfg && page.gameCfg.dirty
                                onClicked: page.trySave()
                            }

                            ArkButton {
                                text: "启动游戏"
                                implicitHeight: 40
                                primary: true
                                enabled: page.gameInfo.launchable === true && Runtime.ready
                                         && page.gameCfg && !page.gameCfg.dirty
                                onClicked: page.launch()
                            }
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "配置文件"
                            value: page.gameCfg ? page.gameCfg.filePath : ""
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.colors.rule
                        }

                        ScrollView {
                            id: detailScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded

                            ColumnLayout {
                                width: detailScroll.availableWidth
                                spacing: 12

                                SectionHeader {
                                    Layout.fillWidth: true
                                    index: "01"
                                    english: "BASIC"
                                    title: "基础配置"
                                }

                                Repeater {
                                    model: page.fieldsFor("基础")

                                    delegate: ConfigField {
                                        Layout.fillWidth: true
                                        config: page.gameCfg
                                        configKey: modelData.key
                                        title: modelData.title
                                        description: modelData.description
                                        hint: modelData.hint
                                        type: modelData.type
                                        options: Configs.runnerNames
                                    }
                                }

                                SectionHeader {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    index: "02"
                                    english: "ADVANCED"
                                    title: "高级参数"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    ArkButton {
                                        text: page.advanced ? "收起高级参数" : "展开高级参数"
                                        implicitHeight: 36
                                        ghost: true
                                        onClicked: page.advanced = !page.advanced
                                    }

                                    MicroLabel {
                                        label: "WORKDIR / PREFIX / UMU ID"
                                        color: Theme.colors.disabled
                                        microSize: 8
                                        tracking: 1.0
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Repeater {
                                    model: page.advanced ? page.fieldsFor("高级") : []

                                    delegate: ConfigField {
                                        Layout.fillWidth: true
                                        config: page.gameCfg
                                        configKey: modelData.key
                                        title: modelData.title
                                        description: modelData.description
                                        hint: modelData.hint
                                        type: modelData.type
                                    }
                                }

                                ValidationList {
                                    Layout.fillWidth: true
                                    issues: page.issues
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: page.issues.length === 0 && page.gameCfg
                                             && !page.gameCfg.exists
                                    text: "配置文件尚不存在。先通过「添加游戏配置」从示例模板创建。"
                                    color: Theme.colors.warn
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    ArkButton {
                                        text: "原始编辑器"
                                        implicitHeight: 40
                                        ghost: true
                                        enabled: page.gameCfg && page.gameCfg.exists
                                        onClicked: rawEditorDialog.openWith(
                                            "游戏配置原始编辑器",
                                            page.gameCfg.filePath,
                                            page.gameCfg.text,
                                            false)
                                    }

                                    MicroLabel {
                                        label: "大窗口编辑 / 保留注释与顺序 / 双向滚动"
                                        color: Theme.colors.disabled
                                        microSize: 8
                                        tracking: 1.0
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Item { Layout.preferredHeight: 8 }
                            }
                        }

                        // 底部：启动条件与隔离说明
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 6
                                height: 6
                                color: page.gameInfo.launchable ? Theme.colors.state
                                                                : Theme.colors.warn
                            }

                            MicroLabel {
                                Layout.fillWidth: true
                                label: page.gameInfo.launchable
                                       ? "启动命令：bash " + Games.launcherForSlug(page.selectedSlug)
                                       : (page.gameInfo.status ? page.gameInfo.status
                                                               : "需要先完成配置")
                                color: page.gameInfo.launchable ? Theme.colors.muted
                                                                : Theme.colors.warn
                                microSize: 9
                                tracking: 0.5
                                elide: Text.ElideMiddle
                            }

                            MicroLabel {
                                label: "隔离环境：CONFIG_DIR / CACHE_DIR / DATA_DIR / TEMP_DIR"
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 0.6
                            }
                        }
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: saveDialog
        title: "配置存在 " + page.issues.length + " 项警告"
        message: "这些警告不会阻止保存，但可能导致启动失败。建议先修正 game.exe 与 runner.name。仍要保存吗？"
        confirmText: "仍然保存"
        onAccepted: page.doSave()
    }

    RawEditorDialog {
        id: rawEditorDialog

        onApplyRequested: function (text) {
            if (!page.gameCfg) {
                return;
            }
            const result = page.gameCfg.applyRawText(text);
            if (result.ok) {
                page.refreshIssues();
                rawEditorDialog.markApplied();
                page.host.showToast("已应用到内存，保存后写入磁盘");
            } else {
                page.host.showToast("无法应用：" + result.error);
            }
        }

        onSaveRequested: function (text) {
            if (!page.gameCfg) {
                return;
            }
            const applied = page.gameCfg.applyRawText(text);
            if (!applied.ok) {
                page.host.showToast("无法应用：" + applied.error);
                return;
            }
            if (page.doSave()) {
                rawEditorDialog.close();
            }
        }
    }

    // 添加游戏配置
    Popup {
        id: addDialog
        objectName: "addGameDialog"
        modal: true
        focus: true
        padding: 24
        width: Math.min(600, Overlay.overlay ? Overlay.overlay.width - 80 : 600)
        height: Math.min(640, Overlay.overlay ? Overlay.overlay.height - 60 : 640)
        anchors.centerIn: Overlay.overlay
        closePolicy: Popup.CloseOnEscape

        background: ChamferedPanel {
            cut: 12
            contentMargin: 0
        }

        contentItem: ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                MicroLabel {
                    label: "ADD GAME CONFIG"
                    color: Theme.colors.signal
                    microSize: 10
                    tracking: 1.6
                }

                Item { Layout.fillWidth: true }

                MicroLabel {
                    label: "来源：config/games.examples"
                    color: Theme.colors.disabled
                    microSize: 9
                    tracking: 0.8
                }
            }

            Text {
                Layout.fillWidth: true
                text: "从上游示例模板复制配置到隔离的 CONFIG_DIR。已存在的配置不会被覆盖。"
                color: Theme.colors.muted
                font.family: App.uiFontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.colors.rule
            }

            Item {
                Layout.fillWidth: true
                height: 20

                MicroLabel {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    label: "游戏 / GAME"
                    color: Theme.colors.disabled
                    microSize: 8
                    tracking: 1.2
                }

                MicroLabel {
                    anchors.right: actionHeader.left
                    anchors.rightMargin: 12
                    width: 116
                    label: "状态 / STATUS"
                    color: Theme.colors.disabled
                    microSize: 8
                    tracking: 1.2
                }

                MicroLabel {
                    id: actionHeader
                    anchors.right: parent.right
                    width: 96
                    label: "操作 / ACTION"
                    color: Theme.colors.disabled
                    microSize: 8
                    tracking: 1.2
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.colors.rule
            }

            Flickable {
                id: templateFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: templateColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: templateColumn
                    width: templateFlick.width
                    spacing: 0

                    Repeater {
                        model: Games.templates

                        delegate: Item {
                            width: templateColumn.width
                            height: 56

                            Rectangle {
                                x: 0
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                color: modelData.configured ? Theme.colors.state : Theme.colors.signal
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.right: statusWrap.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    color: Theme.colors.paper2
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                MicroLabel {
                                    width: parent.width
                                    label: modelData.slug
                                    color: Theme.colors.muted
                                    microSize: 9
                                    tracking: 0.8
                                }
                            }

                            Item {
                                id: statusWrap
                                anchors.right: actionWrap.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 116
                                height: 24

                                ArkTag {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.configured ? "CONFIGURED" : "TEMPLATE"
                                    kind: modelData.configured ? "state" : "neutral"
                                    implicitHeight: 22
                                }
                            }

                            Item {
                                id: actionWrap
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 96
                                height: 34

                                ArkButton {
                                    anchors.right: parent.right
                                    width: 88
                                    text: modelData.configured ? "已存在" : "创建"
                                    implicitHeight: 34
                                    enabled: !modelData.configured && Runtime.ready
                                    onClicked: {
                                        const task = Adapter.createGameConfig(modelData.slug);
                                        if (!task) {
                                            page.host.showToast("无法创建：" + Adapter.lastError);
                                            return;
                                        }
                                        addDialog.close();
                                        Tasks.select(task.id);
                                        page.host.navigate("tasks");
                                    }
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.colors.rule
                                opacity: 0.6
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    visible: Games.templates.length === 0
                    text: "Hyps 组件尚未就绪，无法读取示例配置。"
                    color: Theme.colors.warn
                    font.family: App.uiFontFamily
                    font.pixelSize: 11
                }

                ArkButton {
                    text: "关闭"
                    implicitHeight: 36
                    ghost: true
                    onClicked: addDialog.close()
                }
            }
        }
    }
}
