import QtQuick
import QtQuick.Layouts
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/*
 * MD3 开关行：左侧标题+说明，右侧开关，整行可点。
 *
 * 不要用「MdListItem + 塞一个 MdSwitch 子项」——MdListItem 的正文是绝对定位的，
 * 塞进去的子项会落在 (0,0) 和标题重叠（Settings 页踩过）。
 */
Item {
    id: root

    property string title: ""
    property string description: ""
    property bool checked: false
    property bool enabled: true
    property string accessibleName: ""

    signal toggled(bool checked)

    Layout.fillWidth: true
    implicitWidth: 320
    implicitHeight: root.description.length > 0 ? 64 : 48

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.accessibleName.length > 0 ? root.accessibleName : root.title
    Accessible.checked: root.checked

    function toggle() {
        if (!root.enabled) {
            return;
        }
        root.checked = !root.checked;
        root.toggled(root.checked);
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: Md3.shape.small
        color: Theme.colors.onSurface
        opacity: rowMouse.pressed && root.enabled ? Md3.state.pressed
                 : (rowMouse.containsMouse && root.enabled ? Md3.state.hover : 0)
        Behavior on opacity {
            NumberAnimation { duration: Md3.motion.short2 }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: toggleSwitch.left
        anchors.rightMargin: Md3.space.lg
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        MdText {
            width: parent.width
            role: "bodyLarge"
            text: root.title
            color: root.enabled ? Theme.colors.onSurface : Theme.colors.onSurface
            opacity: root.enabled ? 1 : Md3.disabledContent
            elide: Text.ElideRight
        }

        MdText {
            width: parent.width
            visible: root.description.length > 0
            role: "bodySmall"
            tone: "variant"
            text: root.description
            opacity: root.enabled ? 1 : Md3.disabledContent
            wrapMode: Text.WordWrap
        }
    }

    MdSwitch {
        id: toggleSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        enabled: root.enabled
        accessibleName: root.accessibleName.length > 0 ? root.accessibleName : root.title
        onToggled: function (value) {
            root.checked = value;
            root.toggled(value);
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        anchors.rightMargin: toggleSwitch.width + Md3.space.md
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }
}
