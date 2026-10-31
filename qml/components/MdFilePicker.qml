import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* 目录/文件选择对话框：不依赖平台原生对话框（Wayland 安全）。 */
Dialog {
    id: root

    property string mode: "file"
    property string startPath: ""
    property string nameFilter: "*"
    property string dialogTitle: "选择路径"
    property string selectedPath: ""

    signal selected(string path)

    modal: true
    padding: 0
    anchors.centerIn: Overlay.overlay
    width: Math.min(760, parent ? parent.width - 80 : 760)
    height: Math.min(560, parent ? parent.height - 80 : 560)
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle {
        color: Md3.alpha(Theme.colors.scrim, 0.4)
    }

    background: Rectangle {
        radius: Md3.shape.large
        color: Theme.colors.surfaceContainerHigh
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.margins: Md3.space.lg
            spacing: Md3.space.sm

            MdText {
                role: "titleLarge"
                text: root.dialogTitle
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            MdIconButton {
                iconName: "chevron-left"
                tooltip: "上一级"
                onClicked: model.goUp()
            }

            MdIconButton {
                iconName: "home"
                tooltip: "主目录"
                onClicked: model.setPath(model.homePath())
            }

            MdIconButton {
                iconName: "refresh"
                tooltip: "刷新"
                onClicked: model.refresh()
            }

            MdIconButton {
                iconName: "close"
                tooltip: "关闭"
                onClicked: root.close()
            }
        }

        MdTextField {
            Layout.fillWidth: true
            Layout.leftMargin: Md3.space.lg
            Layout.rightMargin: Md3.space.lg
            monospace: true
            text: model.path
            onEditingFinished: model.setPath(text)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.leftMargin: Md3.space.lg
            Layout.rightMargin: Md3.space.lg
            Layout.topMargin: Md3.space.sm
            spacing: Md3.space.md

            MdSwitch {
                checked: model.showHidden
                accessibleName: "显示隐藏文件"
                onToggled: function (value) { model.showHidden = value }
            }
            MdText {
                role: "bodySmall"
                tone: "variant"
                text: "显示隐藏文件"
            }
            Item { Layout.fillWidth: true }
            MdText {
                visible: model.error.length > 0
                role: "bodySmall"
                color: Theme.colors.error
                text: model.error
                elide: Text.ElideRight
                Layout.maximumWidth: 360
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Md3.space.lg
            Layout.topMargin: Md3.space.sm
            radius: Md3.shape.small
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.outlineVariant
            clip: true

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: model.entries
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: MdScrollBar { }
                spacing: 0

                delegate: Item {
                    width: list.width
                    height: 44

                    readonly property bool isDir: modelData.isDir === true

                    Rectangle {
                        anchors.fill: parent
                        radius: Md3.shape.extraSmall
                        color: root.selectedPath === modelData.path ? Theme.colors.secondaryContainer
                             : (rowMouse.containsMouse ? Md3.hover(Theme.colors.onSurface) : "transparent")
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Md3.space.sm

                        MdIcon {
                            name: isDir ? "folder" : "file"
                            size: 20
                            color: isDir ? Theme.colors.primary : Theme.colors.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MdText {
                            role: "bodyMedium"
                            text: modelData.name
                            width: parent.width - 100
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MdText {
                            role: "labelSmall"
                            tone: "variant"
                            text: modelData.size ? modelData.size : ""
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isDir) {
                                root.selectedPath = modelData.path;
                            } else {
                                root.selectedPath = modelData.path;
                            }
                        }
                        onDoubleClicked: {
                            if (isDir) {
                                model.setPath(modelData.path);
                            } else {
                                root.acceptPath(modelData.path);
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 100000
            Layout.margins: Md3.space.lg
            Layout.topMargin: 0
            spacing: Md3.space.sm

            MdText {
                role: "bodySmall"
                tone: "variant"
                text: root.selectedPath.length > 0 ? root.selectedPath : "未选择"
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                mono: true
            }

            MdButton {
                text: "取消"
                variant: "text"
                onClicked: root.close()
            }

            MdButton {
                text: "选择"
                variant: "filled"
                enabled: root.selectedPath.length > 0
                onClicked: root.acceptPath(root.selectedPath)
            }
        }
    }

    DirectoryModel {
        id: model
        foldersOnly: root.mode === "dir"
        nameFilter: root.mode === "dir" ? "*" : root.nameFilter
    }

    function acceptPath(path) {
        if (path.length === 0) {
            return;
        }
        root.selected(path);
        root.close();
    }

    function openWith(path) {
        model.foldersOnly = root.mode === "dir";
        model.nameFilter = root.mode === "dir" ? "*" : root.nameFilter;
        root.selectedPath = root.mode === "dir" ? path : "";
        model.setPath(path.length > 0 ? path : model.homePath());
        root.open();
    }

    onOpened: openWith(root.startPath)
}
