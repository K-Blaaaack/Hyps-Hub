import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 左侧边缘导航轨：76px（规范范围 64–96px），NN 索引 + 线性图标 + 激活信号条 */
Rectangle {
    id: root

    property string currentPage: "home"
    property var pages: []
    property bool runtimeReady: false
    property string version: ""

    signal navigate(string pageId)

    width: 84
    color: Theme.colors.ink2

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.colors.rule
    }

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Item {
            width: root.width
            height: 84

            Image {
                anchors.centerIn: parent
                width: 42
                height: 42
                source: "qrc:/assets/hyps-hub.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                width: 4
                height: 4
                color: Theme.colors.signal
            }
        }

        Rectangle {
            width: root.width
            height: 1
            color: Theme.colors.rule
        }

        Repeater {
            model: root.pages

            delegate: Item {
                id: navItem
                width: root.width
                height: 72
                activeFocusOnTab: true
                readonly property bool active: root.currentPage === modelData.id

                Keys.onReturnPressed: root.navigate(modelData.id)
                Keys.onSpacePressed: root.navigate(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    color: navItem.active ? Theme.colors.ink3
                           : (hoverArea.containsMouse ? Theme.colors.ink3 : "transparent")
                    opacity: navItem.active || hoverArea.containsMouse ? 1 : 0
                }

                Rectangle {
                    visible: navItem.active
                    width: 2
                    height: 40
                    y: 14
                    color: Theme.colors.signal
                }

                Rectangle {
                    visible: navItem.activeFocus
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.colors.signal
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    MicroLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: modelData.index
                        color: navItem.active ? Theme.colors.signal : Theme.colors.disabled
                        microSize: 8
                        tracking: 1.0
                    }

                    NavIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: modelData.icon
                        color: navItem.active ? Theme.colors.paper : Theme.colors.muted
                        width: 20
                        height: 20
                    }

                    MicroLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: modelData.label
                        color: navItem.active ? Theme.colors.paper : Theme.colors.muted
                        microSize: 10
                        tracking: 0.6
                        mono: false
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        navItem.forceActiveFocus();
                        root.navigate(modelData.id);
                    }
                }

                Accessible.name: modelData.label
                Accessible.description: modelData.english
                Accessible.role: Accessible.PageTab
                Accessible.focusable: true
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 16
        spacing: 8

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 32
            height: 1
            color: Theme.colors.rule
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5

            Rectangle {
                width: 5
                height: 5
                anchors.verticalCenter: parent.verticalCenter
                color: root.runtimeReady ? Theme.colors.state : Theme.colors.danger
            }

            MicroLabel {
                label: root.runtimeReady ? "READY" : "OFFLINE"
                color: root.runtimeReady ? Theme.colors.state : Theme.colors.danger
                microSize: 8
                tracking: 1.0
            }
        }

        MicroLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            label: root.version
            color: Theme.colors.disabled
            microSize: 8
            tracking: 0.8
        }
    }
}
