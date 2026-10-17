import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../components"

/* 配置管理：通用配置 / 运行器 / 路径。所有编辑对象都在隔离的 CONFIG_DIR 内。 */
Item {
    id: page

    property var host
    property int tab: 0
    property var commonIssues: []
    property var runnerIssues: []
    property string runnerName: ""
    property var runnerCfg: runnerName.length > 0 ? Configs.runnerConfig(runnerName) : null
    property bool rawCommon: false
    property bool rawRunner: false

    readonly property var tabDefs: [
        { label: "通用配置", english: "COMMON" },
        { label: "运行器", english: "RUNNERS" },
        { label: "路径", english: "PATHS" }
    ]

    function refreshCommon() {
        commonIssues = Configs.validateCommon();
    }

    function refreshRunner() {
        runnerIssues = page.runnerName.length > 0 ? Configs.validateRunner(page.runnerName) : [];
    }

    function saveCommon() {
        const result = Configs.common.save();
        if (result.ok) {
            page.host.showToast(result.backup ? "已保存配置，备份：" + result.backup : "没有修改或已保存");
            page.refreshCommon();
            Games.refresh();
        } else {
            page.host.showToast("保存失败：" + result.error);
        }
    }

    function trySaveCommon() {
        if (page.commonIssues.length > 0) {
            saveCommonDialog.open();
        } else {
            page.saveCommon();
        }
    }

    function uniqueGroups() {
        const fields = Configs.commonFields;
        const groups = [];
        for (let i = 0; i < fields.length; ++i) {
            if (groups.indexOf(fields[i].group) < 0) {
                groups.push(fields[i].group);
            }
        }
        return groups;
    }

    function fieldsFor(group) {
        const fields = Configs.commonFields;
        const result = [];
        for (let i = 0; i < fields.length; ++i) {
            if (fields[i].group === group) {
                result.push(fields[i]);
            }
        }
        return result;
    }

    function selectRunner(name) {
        page.runnerName = name;
        page.rawRunner = false;
        page.refreshRunner();
    }

    function saveRunner() {
        if (!page.runnerCfg || !Configs.runnerDirectoryIsolated) {
            page.host.showToast("运行器目录来自运行副本，已禁止写入。请先初始化配置。");
            return;
        }
        const result = page.runnerCfg.save();
        if (result.ok) {
            page.host.showToast(result.backup ? "已保存运行器配置，备份：" + result.backup
                                              : "没有修改或已保存");
            Configs.reloadRunners();
            page.refreshRunner();
        } else {
            page.host.showToast("保存失败：" + result.error);
        }
    }

    Component.onCompleted: {
        page.refreshCommon();
        if (Configs.runners.length > 0) {
            page.selectRunner(Configs.runners[0].name);
        }
    }

    Connections {
        target: Configs
        function onReloaded() {
            page.refreshCommon();
            page.refreshRunner();
        }
        function onRunnersChanged() {
            if (page.runnerName.length === 0 && Configs.runners.length > 0) {
                page.selectRunner(Configs.runners[0].name);
            }
            page.refreshRunner();
        }
    }

    Connections {
        target: Configs.common
        function onChanged() { page.refreshCommon(); }
    }

    Connections {
        target: page.runnerCfg
        function onChanged() { page.refreshRunner(); }
    }

    Connections {
        target: Adapter
        function onConfigInitialized() {
            Configs.reloadAll();
            page.refreshCommon();
            page.refreshRunner();
            page.host.showToast("配置目录已初始化");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        PageHeader {
            Layout.fillWidth: true
            index: "04"
            title: "配置"
            english: "CONFIG"
            subtitle: "ISOLATED CONFIG_DIR / BACKUP BEFORE WRITE"

            ArkButton {
                text: Settings.advancedMode ? "关闭高级模式" : "高级模式"
                implicitHeight: 40
                ghost: true
                onClicked: Settings.advancedMode = !Settings.advancedMode
            }

            ArkButton {
                text: "选择编辑器打开配置目录"
                implicitHeight: 40
                ghost: true
                onClicked: AppControl.openDirectory(App.hypsConfigDir)
            }
        }

        // Tab
        Row {
            Layout.fillWidth: true
            spacing: 26

            Repeater {
                model: page.tabDefs

                delegate: Item {
                    width: tabText.implicitWidth + 8
                    height: 42

                    Column {
                        spacing: 6

                        Row {
                            spacing: 8

                            MicroLabel {
                                label: page.tab === index ? "0" + (index + 1) : "0" + (index + 1)
                                color: page.tab === index ? Theme.colors.signal : Theme.colors.disabled
                                microSize: 8
                                tracking: 1.0
                            }

                            Text {
                                id: tabText
                                text: modelData.label
                                color: page.tab === index ? Theme.colors.paper : Theme.colors.muted
                                font.family: App.uiFontFamily
                                font.pixelSize: 13
                                font.weight: page.tab === index ? Font.DemiBold : Font.Normal
                            }

                            MicroLabel {
                                label: modelData.english
                                color: page.tab === index ? Theme.colors.muted : Theme.colors.disabled
                                microSize: 8
                                tracking: 1.0
                            }
                        }

                        Rectangle {
                            width: tabText.implicitWidth + 40
                            height: 2
                            color: page.tab === index ? Theme.colors.signal : "transparent"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.tab = index
                    }
                }
            }

            Item { width: 1; height: 1 }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.rule
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: page.tab

            // ---------------- 通用配置 ----------------
            Item {
                id: commonTab

                EmptyState {
                    anchors.fill: parent
                    visible: !Configs.common.exists
                    indexText: "04"
                    title: "配置目录尚未初始化"
                    description: "点击后会执行上游 init.sh --no-game，把示例配置与运行器配置复制到 "
                                 + App.hypsConfigDir + "。已有的配置文件不会被覆盖。"
                    actionText: "初始化配置"
                    onActionTriggered: Adapter.initializeConfig()
                }

                ScrollView {
                    id: commonScroll
                    anchors.fill: parent
                    visible: Configs.common.exists
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: commonScroll.availableWidth
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ArkButton {
                                text: "保存配置"
                                implicitHeight: 38
                                primary: true
                                enabled: Configs.common.dirty
                                onClicked: page.trySaveCommon()
                            }

                            ArkButton {
                                text: "重新加载"
                                implicitHeight: 38
                                ghost: true
                                onClicked: {
                                    Configs.common.discardChanges();
                                    page.refreshCommon();
                                    page.host.showToast("已从磁盘重新加载");
                                }
                            }

                            ArkButton {
                                text: page.rawCommon ? "关闭原始编辑器" : "原始编辑器"
                                implicitHeight: 38
                                ghost: true
                                onClicked: {
                                    page.rawCommon = !page.rawCommon;
                                    if (page.rawCommon) {
                                        commonRawArea.text = Configs.common.text;
                                    }
                                }
                            }

                            MicroLabel {
                                visible: Configs.common.dirty
                                label: "UNSAVED CHANGES"
                                color: Theme.colors.warn
                                microSize: 9
                                tracking: 1.2
                            }

                            Item { Layout.fillWidth: true }

                            MicroLabel {
                                label: "BACKUP KEEP 10"
                                color: Theme.colors.disabled
                                microSize: 8
                                tracking: 0.8
                            }
                        }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "配置文件"
                            value: Configs.commonConfigPath
                        }

                        Repeater {
                            model: page.uniqueGroups()

                            delegate: ColumnLayout {
                                id: groupBlock
                                Layout.fillWidth: true
                                spacing: 8
                                readonly property int groupIndex: index
                                visible: modelData !== "环境变量" || Settings.advancedMode

                                SectionHeader {
                                    Layout.fillWidth: true
                                    index: (groupBlock.groupIndex + 2 < 10 ? "0" : "")
                                           + (groupBlock.groupIndex + 2)
                                    english: "SECTION"
                                    title: modelData
                                }

                                Repeater {
                                    model: page.fieldsFor(modelData)

                                    delegate: ConfigField {
                                        Layout.fillWidth: true
                                        config: Configs.common
                                        configKey: modelData.key
                                        title: modelData.title
                                        description: modelData.description
                                        hint: modelData.hint
                                        type: modelData.type
                                        options: Configs.runnerNames
                                    }
                                }
                            }
                        }

                        ValidationList {
                            Layout.fillWidth: true
                            issues: page.commonIssues
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: page.rawCommon
                            spacing: 8
                            Layout.topMargin: 6

                            SectionHeader {
                                Layout.fillWidth: true
                                index: "09"
                                english: "RAW"
                                title: "原始配置文本"
                            }

                            TextArea {
                                id: commonRawArea
                                Layout.fillWidth: true
                                Layout.preferredHeight: 220
                                color: Theme.colors.paper2
                                font.family: App.monoFontFamily
                                font.pixelSize: 12
                                selectByMouse: true
                                wrapMode: TextArea.WrapAnywhere
                                leftPadding: 10
                                topPadding: 8
                                background: Rectangle {
                                    color: Theme.colors.codeBg
                                    border.width: 1
                                    border.color: commonRawArea.activeFocus ? Theme.colors.signal
                                                                            : Theme.colors.line
                                }
                            }

                            RowLayout {
                                spacing: 10

                                ArkButton {
                                    text: "应用文本"
                                    implicitHeight: 36
                                    onClicked: {
                                        const result = Configs.common.applyRawText(commonRawArea.text);
                                        page.refreshCommon();
                                        page.host.showToast(result.ok
                                                            ? "已应用到内存，保存后写入磁盘"
                                                            : "无法应用：" + result.error);
                                    }
                                }

                                ArkButton {
                                    text: "应用并保存"
                                    implicitHeight: 36
                                    primary: true
                                    onClicked: {
                                        const applied = Configs.common.applyRawText(commonRawArea.text);
                                        if (!applied.ok) {
                                            page.host.showToast("无法应用：" + applied.error);
                                            return;
                                        }
                                        page.saveCommon();
                                        commonRawArea.text = Configs.common.text;
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        Item { Layout.preferredHeight: 8 }
                    }
                }
            }

            // ---------------- 运行器 ----------------
            Item {
                id: runnerTab

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    ChamferedPanel {
                        Layout.fillWidth: true
                        visible: !Configs.runnerDirectoryIsolated
                        implicitHeight: runnerWarning.implicitHeight + 36
                        contentMargin: 16
                        cut: 8
                        accentColor: Theme.colors.warn

                        ColumnLayout {
                            id: runnerWarning
                            anchors.fill: parent
                            spacing: 6

                            MicroLabel {
                                label: "READ-ONLY SOURCE"
                                color: Theme.colors.warn
                                microSize: 9
                                tracking: 1.4
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "当前运行器配置来自运行副本的 config/runners（未初始化隔离配置）。"
                                      + "为避免弄脏运行副本的 Git 工作区，这里禁止写入。"
                                color: Theme.colors.paper2
                                font.family: App.uiFontFamily
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }

                            ArkButton {
                                text: "初始化隔离配置"
                                implicitHeight: 36
                                primary: true
                                onClicked: Adapter.initializeConfig()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        ChamferedPanel {
                            Layout.preferredWidth: 300
                            Layout.fillHeight: true
                            contentMargin: 14
                            cut: 10

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8

                                SectionHeader {
                                    Layout.fillWidth: true
                                    index: "01"
                                    english: "RUNNERS"
                                    title: "运行器配置"
                                }

                                ListView {
                                    id: runnerList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    model: Configs.runners
                                    spacing: 0
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                    delegate: Item {
                                        width: runnerList.width
                                        height: 58
                                        readonly property bool selected: page.runnerName === modelData.name

                                        Rectangle {
                                            anchors.fill: parent
                                            color: selected ? Theme.colors.ink3
                                                   : (runnerMouse.containsMouse ? Theme.colors.ink3
                                                                                : "transparent")
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
                                            spacing: 8

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    text: modelData.name
                                                    color: Theme.colors.paper2
                                                    font.family: App.monoFontFamily
                                                    font.pixelSize: 12
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.status
                                                    color: modelData.statusLevel === "ok"
                                                           ? Theme.colors.muted : Theme.colors.warn
                                                    font.family: App.monoFontFamily
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                width: 6
                                                height: 6
                                                color: modelData.statusLevel === "ok"
                                                       ? Theme.colors.state : Theme.colors.warn
                                            }
                                        }

                                        MouseArea {
                                            id: runnerMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.selectRunner(modelData.name)
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

                                Text {
                                    Layout.fillWidth: true
                                    visible: Configs.runners.length === 0
                                    text: "没有找到运行器配置。"
                                    color: Theme.colors.muted
                                    font.family: App.uiFontFamily
                                    font.pixelSize: 11
                                }

                                MicroLabel {
                                    Layout.fillWidth: true
                                    label: Configs.runnerDirectory
                                    color: Theme.colors.disabled
                                    microSize: 8
                                    tracking: 0.5
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        ChamferedPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentMargin: 16
                            cut: 10

                            EmptyState {
                                anchors.fill: parent
                                visible: page.runnerName.length === 0
                                indexText: "04"
                                title: "选择左侧运行器"
                                description: "运行器配置会被游戏配置中的 runner.name 引用。"
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                visible: page.runnerName.length > 0
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: page.runnerName
                                        color: Theme.colors.paper
                                        font.family: App.monoFontFamily
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                    }

                                    ArkTag {
                                        text: Configs.runnerDirectoryIsolated ? "EDITABLE" : "READ ONLY"
                                        kind: Configs.runnerDirectoryIsolated ? "state" : "warn"
                                        implicitHeight: 20
                                    }

                                    Item { Layout.fillWidth: true }

                                    ArkButton {
                                        text: "重新加载"
                                        implicitHeight: 36
                                        ghost: true
                                        onClicked: {
                                            if (page.runnerCfg) {
                                                page.runnerCfg.discardChanges();
                                                page.refreshRunner();
                                            }
                                        }
                                    }

                                    ArkButton {
                                        text: "保存"
                                        implicitHeight: 36
                                        primary: true
                                        enabled: Configs.runnerDirectoryIsolated && page.runnerCfg
                                                 && page.runnerCfg.dirty
                                        onClicked: page.saveRunner()
                                    }
                                }

                                InfoRow {
                                    Layout.fillWidth: true
                                    label: "文件"
                                    value: page.runnerCfg ? page.runnerCfg.filePath : ""
                                }

                                InfoRow {
                                    Layout.fillWidth: true
                                    label: "runner.exe"
                                    value: Configs.runnerDetails(page.runnerName).exe
                                           ? Configs.runnerDetails(page.runnerName).exe : "—"
                                }

                                InfoRow {
                                    Layout.fillWidth: true
                                    label: "protonpath"
                                    value: Configs.runnerDetails(page.runnerName).protonpath
                                           ? Configs.runnerDetails(page.runnerName).protonpath : "—"
                                }

                                ValidationList {
                                    Layout.fillWidth: true
                                    issues: page.runnerIssues
                                }

                                TextArea {
                                    id: runnerRawArea
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    readOnly: !Configs.runnerDirectoryIsolated
                                    color: Theme.colors.paper2
                                    font.family: App.monoFontFamily
                                    font.pixelSize: 12
                                    selectByMouse: true
                                    wrapMode: TextArea.WrapAnywhere
                                    leftPadding: 10
                                    topPadding: 8
                                    text: page.runnerCfg ? page.runnerCfg.text : ""
                                    background: Rectangle {
                                        color: Theme.colors.codeBg
                                        border.width: 1
                                        border.color: runnerRawArea.activeFocus ? Theme.colors.signal
                                                                                : Theme.colors.line
                                    }

                                    Connections {
                                        target: page.runnerCfg
                                        function onChanged() {
                                            if (!runnerRawArea.activeFocus) {
                                                runnerRawArea.text = page.runnerCfg.text;
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    ArkButton {
                                        text: "应用文本"
                                        implicitHeight: 36
                                        enabled: Configs.runnerDirectoryIsolated
                                        onClicked: {
                                            if (!page.runnerCfg) {
                                                return;
                                            }
                                            const result = page.runnerCfg.applyRawText(runnerRawArea.text);
                                            page.refreshRunner();
                                            page.host.showToast(result.ok
                                                                ? "已应用到内存，保存后写入磁盘"
                                                                : "无法应用：" + result.error);
                                        }
                                    }

                                    MicroLabel {
                                        label: "RUNNER CONFIG / 原始文本编辑"
                                        color: Theme.colors.disabled
                                        microSize: 8
                                        tracking: 0.8
                                    }

                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- 路径 ----------------
            Item {
                id: pathsTab

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: parent.width
                        spacing: 12

                        SectionHeader {
                            Layout.fillWidth: true
                            index: "01"
                            english: "ISOLATION"
                            title: "目录与隔离"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Hyps Hub 使用独立的 XDG 目录。调用 CLI 时会注入 CONFIG_DIR / CACHE_DIR / "
                                  + "DATA_DIR / TEMP_DIR，因此不会写入 ~/Hyps，也不会与 ~/.config/hypsc、"
                                  + "~/.local/share/hypsc、~/.cache/hypsc、/tmp/hypsc 混用。"
                            color: Theme.colors.paper2
                            font.family: App.uiFontFamily
                            font.pixelSize: 12
                            lineHeight: 1.5
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: App.directories

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    MicroLabel {
                                        Layout.preferredWidth: 120
                                        label: modelData.name
                                        color: Theme.colors.signal
                                        microSize: 9
                                        tracking: 1.0
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.path
                                        color: Theme.colors.paper2
                                        font.family: App.monoFontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideMiddle
                                    }

                                    ArkButton {
                                        text: "打开"
                                        implicitHeight: 32
                                        ghost: true
                                        font.pixelSize: 9
                                        onClicked: AppControl.openDirectory(modelData.path)
                                    }
                                }

                                MicroLabel {
                                    Layout.leftMargin: 130
                                    Layout.fillWidth: true
                                    label: modelData.description
                                    color: Theme.colors.disabled
                                    microSize: 8
                                    tracking: 0.6
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.colors.rule
                                    opacity: 0.5
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 8 }
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: saveCommonDialog
        title: "通用配置存在 " + page.commonIssues.length + " 项警告"
        message: "这些项可能导致启动失败或功能不可用。仍要保存吗？"
        confirmText: "仍然保存"
        onAccepted: page.saveCommon()
    }
}
