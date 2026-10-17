import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HypsHub 1.0

/* 内置路径选择器：不依赖平台原生文件对话框，Wayland / X11 行为一致 */
Popup {
    id: popup

    property string mode: "file" // file | dir
    property string startPath: ""
    property string nameFilter: "*"
    property string dialogTitle: "选择路径"
    property string selectedPath: ""

    signal accepted(string path)

    modal: true
    focus: true
    padding: 24
    closePolicy: Popup.CloseOnEscape
    width: Math.min(760, (Overlay.overlay ? Overlay.overlay.width : 920) - 80)
    height: Math.min(580, (Overlay.overlay ? Overlay.overlay.height : 760) - 80)
    anchors.centerIn: Overlay.overlay

    background: ChamferedPanel {
        cut: 12
        contentMargin: 0
    }

    DirectoryModel {
        id: dirModel
        foldersOnly: popup.mode === "dir"
        nameFilter: popup.mode === "file" ? popup.nameFilter : ""
    }

    onOpened: {
        selectedPath = "";
        dirModel.setPath(startPath.length > 0 ? startPath : dirModel.homePath());
        pathInput.text = dirModel.path;
    }

    contentItem: ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MicroLabel {
                label: popup.dialogTitle
                color: Theme.colors.paper
                microSize: 11
                tracking: 1.6
            }

            Item { Layout.fillWidth: true }

            MicroLabel {
                label: popup.mode === "dir" ? "DIRECTORY" : "FILE"
                color: Theme.colors.signal
                microSize: 9
                tracking: 1.4
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.rule
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: pathInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Theme.colors.paper2
                font.family: App.monoFontFamily
                font.pixelSize: 12
                selectByMouse: true
                leftPadding: 10
                placeholderText: "/path/to"
                placeholderTextColor: Theme.colors.disabled
                onEditingFinished: {
                    dirModel.setPath(text);
                    text = dirModel.path;
                }

                background: Rectangle {
                    color: Theme.colors.ink
                    border.width: 1
                    border.color: pathInput.activeFocus ? Theme.colors.signal : Theme.colors.line
                }
            }

            ArkButton {
                text: "上级"
                implicitHeight: 40
                onClicked: {
                    dirModel.goUp();
                    pathInput.text = dirModel.path;
                    selectedPath = "";
                }
            }

            ArkButton {
                text: dirModel.showHidden ? "隐藏文件 ON" : "隐藏文件 OFF"
                implicitHeight: 40
                ghost: true
                onClicked: dirModel.showHidden = !dirModel.showHidden
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.colors.codeBg
            border.width: 1
            border.color: Theme.colors.rule

            ListView {
                id: fileList
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                model: dirModel.entries
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    width: fileList.width
                    height: 34
                    property bool isDir: modelData.isDir
                    property string entryPath: modelData.path

                    Rectangle {
                        anchors.fill: parent
                        color: popup.selectedPath === parent.entryPath ? Theme.colors.ink3
                             : (rowMouse.containsMouse ? Theme.colors.ink3 : "transparent")
                        opacity: popup.selectedPath === parent.entryPath || rowMouse.containsMouse ? 1 : 0
                    }

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: popup.selectedPath === parent.entryPath ? Theme.colors.signal : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 10
                            height: 10
                            color: isDir ? Theme.colors.signal : Theme.colors.line
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: isDir ? Theme.colors.paper : Theme.colors.paper2
                            font.family: App.monoFontFamily
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                        }

                        MicroLabel {
                            label: modelData.isDir ? "DIR" : modelData.size
                            color: Theme.colors.disabled
                            microSize: 9
                            tracking: 0.8
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            if (isDir) {
                                popup.selectedPath = "";
                                dirModel.setPath(entryPath);
                                pathInput.text = dirModel.path;
                            } else {
                                popup.selectedPath = entryPath;
                            }
                        }
                        onDoubleClicked: {
                            if (isDir) {
                                dirModel.setPath(entryPath);
                                pathInput.text = dirModel.path;
                            } else {
                                popup.selectedPath = entryPath;
                                popup.accepted(entryPath);
                                popup.close();
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: dirModel.entries.length === 0
                text: dirModel.error.length > 0 ? dirModel.error : "此目录为空"
                color: Theme.colors.muted
                font.family: App.uiFontFamily
                font.pixelSize: 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: popup.selectedPath.length > 0 ? popup.selectedPath
                     : (popup.mode === "dir" ? dirModel.path : "")
                color: Theme.colors.muted
                font.family: App.monoFontFamily
                font.pixelSize: 11
                elide: Text.ElideMiddle
            }

            ArkButton {
                text: "取消"
                implicitHeight: 40
                ghost: true
                onClicked: popup.close()
            }

            ArkButton {
                text: popup.mode === "dir" ? "选择当前目录" : "选择文件"
                implicitHeight: 40
                primary: true
                enabled: popup.mode === "dir" || popup.selectedPath.length > 0
                onClicked: {
                    const chosen = popup.mode === "dir" ? dirModel.path : popup.selectedPath;
                    popup.accepted(chosen);
                    popup.close();
                }
            }
        }
    }
}
