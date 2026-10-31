import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 snackbar：inverseSurface 底 + inverseOnSurface 文字 + 4dp 圆角 + 48dp 高，
 * 左侧 16dp 内边距，单行省略；actionText 非空时右侧出现一个 inversePrimary 文字按钮。
 *
 * 冻结 API：
 *   message / actionText / show(text) / actionTriggered()
 *
 * 行为：show(text) 打开并重置 4 秒计时；再次调用会重新计时。点动作按钮触发
 * actionTriggered() 并收起。进入/退出用 y 位移 + 淡入（short4 / medium2）。
 *
 * 注意：Popup 不支持 anchors —— x/y 由调用方给（Main 用 x/y 摆在右下），
 * 这里只保证 width 按内容算（min 344，max 672，含左右各 16 内边距）、height 48。
 */
Popup {
    id: root

    property string message: ""
    property string actionText: ""

    signal actionTriggered()

    function show(text) {
        if (typeof text === "string") {
            root.message = text;
        }
        root.open();
        hideTimer.restart();
    }

    modal: false
    focus: false
    padding: 0
    z: 100
    closePolicy: Popup.NoAutoClose
    height: Md3.space.xxxl
    width: Math.min(Md3.size.snackbarMaxWidth,
                    Math.max(Md3.size.snackbarMinWidth, shell.implicitWidth))

    contentItem: Item {
        id: shell
        implicitWidth: row.implicitWidth + Md3.space.lg * 2
        implicitHeight: root.height

        Item {
            id: body
            y: 0
            width: shell.width
            height: shell.height

            // 半透明阴影（软件渲染下不用 shader 阴影）
            Rectangle {
                x: 0
                y: 3
                width: body.width
                height: body.height
                radius: Md3.shape.extraSmall
                color: Md3.alpha(Theme.colors.shadow, 0.24)
            }

            Rectangle {
                id: bar
                width: body.width
                height: body.height
                radius: Md3.shape.extraSmall
                color: Theme.colors.inverseSurface
                Accessible.role: Accessible.AlertMessage
                Accessible.name: root.message
            }

            RowLayout {
                id: row
                x: Md3.space.lg
                y: 0
                width: body.width - Md3.space.lg * 2
                height: body.height
                spacing: Md3.space.sm

                MdText {
                    Layout.fillWidth: true
                    role: "bodyMedium"
                    text: root.message
                    color: Theme.colors.inverseOnSurface
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                }

                // 动作：文字按钮（颜色 inversePrimary；MdButton 的 text 变体用 primary，
                // 所以这里就地实现一个同规格的小按钮）
                Item {
                    id: actionButton
                    visible: root.actionText.length > 0
                    implicitWidth: actionLabel.implicitWidth + Md3.space.md * 2
                    implicitHeight: Md3.size.button
                    Layout.alignment: Qt.AlignVCenter
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: root.actionText

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.colors.inversePrimary
                        opacity: actionMouse.pressed ? Md3.state.pressed
                                                     : (actionMouse.containsMouse ? Md3.state.hover : 0)
                        Behavior on opacity {
                            NumberAnimation { duration: Md3.motion.short2; easing.type: Easing.OutCubic }
                        }
                    }

                    // 键盘焦点环
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Md3.space.xxs
                        radius: height / 2
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.colors.inversePrimary
                        opacity: actionButton.activeFocus ? 0.9 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Md3.motion.short2 }
                        }
                    }

                    MdText {
                        id: actionLabel
                        anchors.centerIn: parent
                        role: "labelLarge"
                        text: root.actionText
                        color: Theme.colors.inversePrimary
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.actionTriggered();
                            root.close();
                        }
                    }

                    Keys.onReturnPressed: {
                        root.actionTriggered();
                        root.close();
                    }
                    Keys.onSpacePressed: {
                        root.actionTriggered();
                        root.close();
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 4000
        repeat: false
        onTriggered: root.close()
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Md3.motion.short4
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: body
                property: "y"
                from: Md3.space.md
                to: 0
                duration: Md3.motion.short4
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Md3.motion.medium2
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: body
                property: "y"
                from: 0
                to: Md3.space.md
                duration: Md3.motion.medium2
                easing.type: Easing.InCubic
            }
        }
    }
}
