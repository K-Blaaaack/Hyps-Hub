import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* 日志视图：工具行（计数/过滤/复制/清空）+ 等宽日志区。 */
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property var logModel: null
    property string title: "输出"
    property bool busy: false
    property bool autoScroll: true

    signal clearRequested()

    implicitHeight: 320
    radius: Md3.shape.medium
    color: Theme.colors.surfaceContainerLow
    border.width: 1
    border.color: Theme.colors.outlineVariant

    function streamColor(stream) {
        if (stream === 2 || stream === "2" || stream === "stderr") {
            return Theme.colors.error;
        }
        if (stream === 1 || stream === "1" || stream === "stdout") {
            return Theme.colors.onSurface;
        }
        return Theme.colors.onSurfaceVariant;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Md3.space.md
        spacing: Md3.space.sm

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            spacing: Md3.space.sm

            MdText {
                role: "titleSmall"
                text: root.title
            }

            MdText {
                role: "labelSmall"
                tone: "variant"
                text: {
                    if (!root.logModel) {
                        return "—";
                    }
                    const visible = root.logModel.visibleCount;
                    const total = root.logModel.count;
                    return visible === total ? total + " 行" : visible + " / " + total + " 行";
                }
            }

            MdTag {
                visible: root.logModel ? root.logModel.truncated : false
                text: "已截断"
                status: "warning"
            }

            MdTag {
                visible: root.busy
                text: "运行中"
                status: "primary"
            }

            Item { Layout.fillWidth: true }

            MdSearchField {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 36
                compact: true
                placeholder: "过滤日志"
                onEdited: function (text) {
                    if (root.logModel) {
                        root.logModel.filter = text;
                    }
                }
            }

            MdIconButton {
                iconName: "copy"
                size: 32
                iconSize: 18
                tooltip: "复制当前视图"
                onClicked: if (root.logModel) root.logModel.copyFilteredToClipboard()
            }

            MdIconButton {
                iconName: "trash"
                size: 32
                iconSize: 18
                tooltip: "清空视图"
                onClicked: root.clearRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Md3.shape.small
            color: Theme.colors.codeSurface
            border.width: 1
            border.color: Theme.colors.outlineVariant
            clip: true

            ListView {
                id: view
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                model: root.logModel ? root.logModel.filtered : null
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 400
                ScrollBar.vertical: MdScrollBar { }

                onCountChanged: {
                    if (root.autoScroll) {
                        Qt.callLater(function () { view.positionViewAtEnd() });
                    }
                }

                onMovementEnded: root.autoScroll = view.atYEnd

                delegate: Row {
                    width: view.width
                    spacing: 8

                    MdText {
                        role: "labelSmall"
                        mono: true
                        color: Md3.alpha(Theme.colors.onSurfaceVariant, 0.7)
                        text: model.lineNumber !== undefined ? String(model.lineNumber) : ""
                        width: 40
                        horizontalAlignment: Text.AlignRight
                    }

                    MdText {
                        role: "bodySmall"
                        mono: true
                        color: root.streamColor(model.stream)
                        text: model.text !== undefined ? String(model.text) : ""
                        width: Math.max(0, view.width - 52)
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }

            MdText {
                anchors.centerIn: parent
                visible: !root.logModel || root.logModel.count === 0
                role: "bodySmall"
                tone: "variant"
                text: root.busy ? "等待输出…" : "暂无日志"
            }
        }
    }
}
