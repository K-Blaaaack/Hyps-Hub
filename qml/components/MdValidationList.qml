import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3
import QtQuick.Layouts

/* 校验结果列表：issues = [{level, message}]。 */
Item {
    id: root
    Layout.fillWidth: true
    implicitWidth: 320

    property var issues: []
    property string emptyText: "没有发现问题"

    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 6

        Row {
            width: parent.width
            spacing: 8
            visible: !root.issues || root.issues.length === 0

            MdIcon {
                name: "check-circle"
                size: 16
                color: Theme.colors.success
                anchors.verticalCenter: parent.verticalCenter
            }

            MdText {
                role: "bodySmall"
                tone: "variant"
                text: root.emptyText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Repeater {
            model: root.issues || []

            delegate: Row {
                width: column.width
                spacing: 8

                readonly property bool isError: String(modelData.level) === "error"

                MdIcon {
                    name: isError ? "error" : "warning"
                    size: 16
                    color: isError ? Theme.colors.error : Theme.colors.warning
                    anchors.verticalCenter: parent.verticalCenter
                }

                MdText {
                    role: "bodySmall"
                    color: isError ? Theme.colors.error : Theme.colors.warning
                    text: String(modelData.message)
                    width: parent.width - 24
                    wrapMode: Text.WordWrap
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
