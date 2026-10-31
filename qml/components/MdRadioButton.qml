import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 单选按钮：20dp 圆环 + 标签，整行 40dp 可点。 */
Item {
    id: root

    property bool checked: false
    property string text: ""
    property string value: ""

    signal toggled(bool value)

    implicitWidth: row.implicitWidth
    implicitHeight: 40
    activeFocusOnTab: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: root.text
    Accessible.checked: root.checked

    Keys.onSpacePressed: root.select()

    function select() {
        if (!root.enabled || root.checked) {
            return;
        }
        root.checked = true;
        root.toggled(true);
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Md3.space.sm

        Item {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: root.checked ? Theme.colors.primary : Theme.colors.onSurfaceVariant
            }

            Rectangle {
                anchors.centerIn: parent
                visible: root.checked
                width: 10
                height: 10
                radius: 5
                color: Theme.colors.primary
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.colors.primary
                opacity: root.activeFocus ? 1 : 0
            }
        }

        MdText {
            role: "bodyLarge"
            text: root.text
            color: Theme.colors.onSurface
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.select();
        }
    }
}
