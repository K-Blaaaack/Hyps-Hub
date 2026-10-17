import QtQuick
import QtQuick.Layouts
import HypsHub 1.0

/* 校验问题列表：语法/语义警告，保存前展示 */
Item {
    id: root

    property var issues: []

    implicitHeight: list.implicitHeight
    visible: count > 0

    readonly property int count: issues ? issues.length : 0

    ColumnLayout {
        id: list
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: root.issues

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ArkTag {
                    text: modelData.level === "error" ? "ERROR" : "WARN"
                    kind: modelData.level === "error" ? "danger" : "warn"
                    implicitHeight: 20
                }

                Text {
                    Layout.fillWidth: true
                    text: (modelData.key ? modelData.key + " — " : "") + modelData.message
                    color: modelData.level === "error" ? Theme.colors.danger
                                                       : Theme.colors.warn
                    font.family: App.uiFontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
