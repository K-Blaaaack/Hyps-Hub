import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import HypsHub 1.0
import "components"
import "pages"

ApplicationWindow {
    id: window

    visible: true
    title: "Hyps Hub"
    color: Theme.colors.ink
    width: 1180
    height: 760
    minimumWidth: 1040
    minimumHeight: 720

    property string currentPage: "home"

    readonly property var pageDefs: [
        { id: "home", index: "01", label: "首页", english: "OVERVIEW", icon: "home" },
        { id: "games", index: "02", label: "游戏", english: "GAMES", icon: "games" },
        { id: "tasks", index: "03", label: "任务", english: "TASKS", icon: "tasks" },
        { id: "config", index: "04", label: "配置", english: "CONFIG", icon: "config" },
        { id: "diagnostics", index: "05", label: "诊断", english: "DIAGNOSTICS", icon: "diagnostics" },
        { id: "settings", index: "06", label: "设置", english: "SETTINGS", icon: "settings" },
        { id: "about", index: "07", label: "关于", english: "ABOUT", icon: "about" }
    ]

    property int currentIndex: {
        for (let i = 0; i < pageDefs.length; ++i) {
            if (pageDefs[i].id === currentPage) {
                return i;
            }
        }
        return 0;
    }

    function navigate(pageId) {
        if (!pageId || pageId.length === 0) {
            return;
        }
        window.currentPage = pageId;
        Settings.lastPage = pageId;
    }

    function showToast(message) {
        if (!message || message.length === 0) {
            return;
        }
        toast.show(message);
    }

    function saveGeometry() {
        Settings.saveWindowGeometry(window.x, window.y, window.width, window.height,
                                    window.visibility === Window.Maximized);
    }

    function confirmQuit() {
        quitDialog.open();
    }

    function quitNow() {
        saveGeometry();
        AppControl.quitApplication();
    }

    Component.onCompleted: {
        const geometry = Settings.windowGeometry();
        if (geometry.width >= 640 && geometry.height >= 480) {
            window.width = geometry.width;
            window.height = geometry.height;
        }
        if (!App.wayland) {
            if (geometry.x !== undefined) {
                window.x = geometry.x;
            }
            if (geometry.y !== undefined) {
                window.y = geometry.y;
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
        if (Tasks.activeCount > 0) {
            close.accepted = false;
            quitDialog.open();
        }
    }

    Item {
        anchors.fill: parent

        GridBackdrop {
            anchors.fill: parent
        }

        // 主界面
        Item {
            anchors.fill: parent
            visible: Runtime.ready

            RowLayout {
                anchors.fill: parent
                spacing: 0

                NavRail {
                    Layout.fillHeight: true
                    currentPage: window.currentPage
                    pages: window.pageDefs
                    runtimeReady: Runtime.ready
                    version: "v" + App.appVersion
                    onNavigate: function (pageId) { window.navigate(pageId) }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    TopBar {
                        Layout.fillWidth: true
                        pageTitle: window.currentPage
                        pageEnglish: window.pageDefs[window.currentIndex].english
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: window.currentIndex

                        HomePage { host: window }
                        GamesPage { host: window }
                        TasksPage { host: window }
                        ConfigPage { host: window }
                        DiagnosticsPage { host: window }
                        SettingsPage { host: window }
                        AboutPage { host: window }
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

        // Toast
        Rectangle {
            id: toast

            property string message: ""

            width: Math.min(640, toastText.implicitWidth + 52)
            height: 46
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            anchors.bottomMargin: 20
            color: Theme.colors.ink2
            border.width: 1
            border.color: Theme.colors.lineHover
            opacity: 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Rectangle {
                x: 0
                y: 8
                width: 2
                height: parent.height - 16
                color: Theme.colors.signal
            }

            Text {
                id: toastText
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                text: toast.message
                color: Theme.colors.paper2
                font.family: App.uiFontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Timer {
                id: toastTimer
                interval: 4200
                onTriggered: toast.opacity = 0
            }

            function show(text) {
                message = text;
                opacity = 1;
                toastTimer.restart();
            }
        }
    }

    ConfirmDialog {
        id: quitDialog
        title: "仍有任务正在运行"
        message: "关闭窗口会取消所有运行中的任务（包括游戏启动），并向整个进程组发送终止信号。确定退出吗？"
        confirmText: "取消任务并退出"
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
