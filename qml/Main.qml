import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import HypsHub 1.0
import "components"
import "pages"
import "theme/Md3.js" as Md3

/*
 * 应用外壳：MD3 导航轨 + 顶部应用栏 + 页面栈。
 *
 * 页面契约（pages/*.qml 都依赖它）：
 *   property var host      -> 本窗口，页面通过 host.navigate(id) / host.showToast(text) 交互
 *   Main 负责页面标题（顶部应用栏），页面内部不要再画一级标题。
 */
ApplicationWindow {
    id: window

    visible: true
    title: "Hyps Hub"
    color: Theme.colors.surface
    width: 1180
    height: 760
    minimumWidth: 1040
    minimumHeight: 720

    property string currentPage: "home"
    property bool quitHasUnsaved: false
    property bool railExpanded: false

    readonly property var pageDefs: [
        { id: "home", label: "首页", english: "OVERVIEW", icon: "home" },
        { id: "games", label: "游戏", english: "GAMES", icon: "games" },
        { id: "tasks", label: "任务", english: "TASKS", icon: "tasks" },
        { id: "config", label: "配置", english: "CONFIG", icon: "config" },
        { id: "diagnostics", label: "诊断", english: "DIAGNOSTICS", icon: "diagnostics" },
        { id: "settings", label: "设置", english: "SETTINGS", icon: "settings" },
        { id: "about", label: "关于", english: "ABOUT", icon: "about" }
    ]

    property int currentIndex: {
        for (let i = 0; i < pageDefs.length; ++i) {
            if (pageDefs[i].id === currentPage) {
                return i;
            }
        }
        return 0;
    }

    readonly property var currentDef: pageDefs[Math.max(0, currentIndex)]

    function navigate(pageId) {
        if (!pageId || pageId.length === 0) {
            return;
        }
        if (window.currentPage === pageId) {
            return;
        }
        window.currentPage = pageId;
        Settings.lastPage = pageId;
        pageFade.restart();
    }

    function showToast(message) {
        if (!message || message.length === 0) {
            return;
        }
        snackbar.show(message);
    }

    function saveGeometry() {
        Settings.saveWindowGeometry(window.x, window.y, window.width, window.height,
                                    window.visibility === Window.Maximized);
    }

    function confirmQuit() {
        window.quitHasUnsaved = Configs.hasUnsavedChanges();
        quitDialog.open();
    }

    function quitNow() {
        saveGeometry();
        AppControl.quitApplication();
    }

    Component.onCompleted: {
        const geometry = Settings.windowGeometry();
        if (hypsScreenshotMode) {
            // 离屏平台通常报告 800×800；截图按配置尺寸渲染，不按虚拟屏幕裁剪。
            window.width = geometry.width >= 640 ? geometry.width : 1440;
            window.height = geometry.height >= 480 ? geometry.height : 900;
        } else {
            const maxWidth = Screen.desktopAvailableWidth > 0
                           ? Screen.desktopAvailableWidth : window.minimumWidth;
            const maxHeight = Screen.desktopAvailableHeight > 0
                            ? Screen.desktopAvailableHeight : window.minimumHeight;
            if (geometry.width >= 640 && geometry.height >= 480) {
                window.width = Math.min(Math.max(geometry.width, window.minimumWidth), maxWidth);
                window.height = Math.min(Math.max(geometry.height, window.minimumHeight), maxHeight);
            }
            if (!App.wayland) {
                const maxX = Math.max(0, maxWidth - 120);
                const maxY = Math.max(0, maxHeight - 120);
                if (typeof geometry.x === "number" && isFinite(geometry.x)
                    && geometry.x >= 0 && geometry.x <= maxX) {
                    window.x = geometry.x;
                }
                if (typeof geometry.y === "number" && isFinite(geometry.y)
                    && geometry.y >= 0 && geometry.y <= maxY) {
                    window.y = geometry.y;
                }
            }
        }
        if (geometry.maximized) {
            window.showMaximized();
        }

        const last = Settings.lastPage;
        let valid = false;
        for (let i = 0; i < pageDefs.length; ++i) {
            if (pageDefs[i].id === last) {
                valid = true;
                break;
            }
        }
        window.currentPage = valid ? last : "home";

        if (Settings.loadWarning.length > 0) {
            window.showToast(Settings.loadWarning);
        }
        if (Runtime.errorMessage.length > 0) {
            window.showToast(Runtime.errorMessage);
        }
    }

    onClosing: function (close) {
        window.saveGeometry();
        window.quitHasUnsaved = Configs.hasUnsavedChanges();
        if (Tasks.activeCount > 0 || window.quitHasUnsaved) {
            close.accepted = false;
            quitDialog.open();
        }
    }

    Item {
        anchors.fill: parent

        // 主界面
        Item {
            anchors.fill: parent
            visible: Runtime.ready

            RowLayout {
                anchors.fill: parent
                spacing: 0

                MdNavRail {
                    Layout.fillHeight: true
                    currentPage: window.currentPage
                    pages: window.pageDefs
                    badges: ({ "tasks": Tasks.activeCount })
                    runtimeReady: Runtime.ready
                    version: "v" + App.appVersion
                    onNavigate: function (pageId) { window.navigate(pageId) }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    MdTopAppBar {
                        Layout.fillWidth: true
                        title: window.currentDef.label
                        subtitle: window.currentDef.english

                        MdTag {
                            text: EnvReport.hasReport
                                  ? ("ENV " + EnvReport.requiredPassed + "/" + EnvReport.requiredTotal)
                                  : "ENV —"
                            status: EnvReport.hasReport
                                    ? (EnvReport.requiredFailed > 0 ? "error" : "success")
                                    : "neutral"
                        }

                        MdTag {
                            visible: Runtime.updateAvailable
                            text: "可更新 " + Runtime.behindCount
                            status: "primary"
                            iconName: "download"
                        }

                        MdTag {
                            text: Runtime.ready ? "组件就绪" : "组件缺失"
                            status: Runtime.ready ? "success" : "error"
                            iconName: "git"
                        }

                        MdButton {
                            text: "检查环境"
                            variant: "tonal"
                            iconName: "refresh"
                            enabled: Runtime.ready
                            onClicked: Adapter.checkEnvironment()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        StackLayout {
                            id: pageStack
                            anchors.fill: parent
                            currentIndex: window.currentIndex

                            HomePage { host: window }
                            GamesPage { host: window }
                            TasksPage { host: window }
                            ConfigPage { host: window }
                            DiagnosticsPage { host: window }
                            SettingsPage { host: window }
                            AboutPage { host: window }
                        }

                        SequentialAnimation {
                            id: pageFade
                            NumberAnimation {
                                target: pageStack
                                property: "opacity"
                                to: 0.35
                                duration: Md3.motion.short3
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: pageStack
                                property: "opacity"
                                to: 1
                                duration: Md3.motion.medium2
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

        // 首次初始化
        OnboardingPage {
            anchors.fill: parent
            visible: !Runtime.ready
            host: window
        }
    }

    MdSnackbar {
        id: snackbar
        // Snackbar 是 Popup：只支持 x/y，不支持 anchors。
        x: Runtime.ready ? (window.railExpanded ? 280 : 104) : 24
        y: window.height - height - 24
    }

    MdConfirmDialog {
        id: quitDialog
        heading: window.quitHasUnsaved && Tasks.activeCount > 0
                   ? "有未保存的配置，且任务仍在运行"
                   : (window.quitHasUnsaved ? "有未保存的配置" : "仍有任务正在运行")
        message: {
            const parts = [];
            if (window.quitHasUnsaved) {
                parts.push("有配置修改尚未保存，退出会丢失这些修改。");
            }
            if (Tasks.activeCount > 0) {
                parts.push("关闭窗口会取消所有运行中的任务（包括游戏启动），并向整个进程组发送终止信号。");
            }
            parts.push("确定退出吗？");
            return parts.join("\n\n");
        }
        confirmText: window.quitHasUnsaved && Tasks.activeCount > 0
                         ? "取消任务并退出"
                         : (window.quitHasUnsaved ? "放弃修改并退出" : "取消任务并退出")
        cancelText: "返回"
        danger: true
        onAccepted: window.quitNow()
    }

    Connections {
        target: Tasks
        function onTaskFinished(task) {
            if (Settings.notificationsEnabled && !window.active) {
                Notifier.notify("Hyps Hub", task.label + "：" + task.stateText);
            }
            if (task.state === "failed" || task.state === "timeout") {
                window.showToast(task.label + " — "
                                 + (task.errorSummary.length > 0 ? task.errorSummary
                                                                : task.stateText));
            } else if (task.kind === "game") {
                window.showToast(task.label + " 已结束（" + task.stateText + "）");
            }
        }
    }

    Connections {
        target: Runtime
        function onErrorMessageChanged() {
            if (Runtime.errorMessage.length > 0) {
                window.showToast(Runtime.errorMessage);
            }
        }
    }
}
