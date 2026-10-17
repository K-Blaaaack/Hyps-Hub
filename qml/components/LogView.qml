import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/* 日志视图：结构化行号 + stdout/stderr 分色 + 过滤/复制/清空 + 自动滚动 */
Item {
    id: root

    property var logModel: null
    property string title: "日志"
    property string subtitle: ""
    property bool busy: false

    property bool autoScroll: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            spacing: 10

            MicroLabel {
                label: root.title
                color: Theme.colors.paper
                microSize: 10
                tracking: 1.4
            }

            MicroLabel {
                label: root.logModel
                       ? (root.logModel.visibleCount + " / " + root.logModel.count)
                       : "0"
                color: Theme.colors.muted
                microSize: 9
                tracking: 1.0
            }

            MicroLabel {
                visible: root.logModel && root.logModel.truncated
                label: "TRUNCATED"
                color: Theme.colors.warn
                microSize: 9
                tracking: 1.2
            }

            Item { Layout.fillWidth: true }

            TextField {
                id: filterField
                Layout.preferredWidth: 180
                Layout.preferredHeight: 30
                placeholderText: "过滤日志"
                placeholderTextColor: Theme.colors.disabled
                color: Theme.colors.paper2
                font.family: App.monoFontFamily
                font.pixelSize: 11
                leftPadding: 8
                selectByMouse: true
                onTextChanged: {
                    if (root.logModel) {
                        root.logModel.filter = text;
                    }
                }

                background: Rectangle {
                    color: Theme.colors.ink
                    border.width: 1
                    border.color: filterField.activeFocus ? Theme.colors.signal : Theme.colors.line
                }
            }

            ArkButton {
                text: "复制"
                implicitHeight: 34
                ghost: true
                enabled: root.logModel !== null
                onClicked: if (root.logModel) root.logModel.copyFilteredToClipboard()
            }

            ArkButton {
                text: "清空视图"
                implicitHeight: 34
                ghost: true
                enabled: root.logModel !== null
                onClicked: if (root.logModel) root.logModel.clear()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.colors.codeBg
            border.width: 1
            border.color: Theme.colors.rule

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                model: root.logModel ? root.logModel.filtered : null
                spacing: 1

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    width: list.width
                    height: Math.max(16, lineText.implicitHeight + 2)

                    Text {
                        id: numberText
                        width: 46
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        text: lineNumber
                        horizontalAlignment: Text.AlignRight
                        color: Theme.colors.disabled
                        font.family: App.monoFontFamily
                        font.pixelSize: 10
                    }

                    Text {
                        id: lineText
                        anchors.left: numberText.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        text: model.text
                        wrapMode: Text.WrapAnywhere
                        color: stream === 1 ? Theme.colors.danger
                             : (stream === 2 ? Theme.colors.muted : Theme.colors.paper2)
                        font.family: App.monoFontFamily
                        font.pixelSize: 12
                        lineHeight: 1.15
                    }
                }

                onCountChanged: {
                    if (root.autoScroll) {
                        Qt.callLater(list.positionViewAtEnd);
                    }
                }
                onMovementEnded: root.autoScroll = atYEnd
            }

            Text {
                anchors.centerIn: parent
                visible: !root.logModel || root.logModel.visibleCount === 0
                text: {
                    if (root.logModel && root.logModel.count > 0) {
                        return "没有匹配的日志行";
                    }
                    return root.busy ? "等待输出…" : "暂无日志";
                }
                color: Theme.colors.muted
                font.family: App.uiFontFamily
                font.pixelSize: 12
            }
        }
    }
}
