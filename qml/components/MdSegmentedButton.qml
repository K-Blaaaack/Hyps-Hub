import QtQuick
import HypsHub 1.0
import "../theme/Md3.js" as Md3

/* MD3 分段按钮：外框 1dp 描边 + 胶囊圆角，选中段用 secondaryContainer。 */
Item {
    id: root

    property var model: []
    property string currentValue: ""
    property string size: "regular"

    signal activated(string value)

    readonly property real segmentHeight: root.size === "small" ? 32 : 40

    implicitHeight: segmentHeight
    implicitWidth: segments.implicitWidth

    function optionValue(option) {
        if (option === undefined || option === null) {
            return "";
        }
        if (typeof option === "object") {
            return option.value !== undefined ? String(option.value) : String(option.text);
        }
        return String(option);
    }

    function optionText(option) {
        if (option !== undefined && option !== null && typeof option === "object") {
            return String(option.text !== undefined ? option.text : option.value);
        }
        return String(option);
    }

    function optionIcon(option) {
        if (option !== undefined && option !== null && typeof option === "object"
                && option.iconName !== undefined) {
            return String(option.iconName);
        }
        return "";
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: Theme.colors.outline
    }

    Row {
        id: segments
        anchors.centerIn: parent
        height: parent.height

        Repeater {
            model: root.model

            delegate: Item {
                id: segment
                height: root.segmentHeight
                width: content.implicitWidth + 32
                readonly property bool selected: root.currentValue === root.optionValue(modelData)

                // 选中块要缩进 3dp：贴着外框画会把 1dp 描边盖掉（右侧尤其明显，
                // 胶囊像从外框里戳出来）
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: height / 2
                    color: segment.selected ? Theme.colors.secondaryContainer : "transparent"

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.colors.onSurface
                        opacity: segMouse.containsMouse && !segment.selected ? Md3.state.hover : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Md3.motion.short2 }
                        }
                    }
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6

                    MdIcon {
                        visible: root.optionIcon(modelData).length > 0
                        name: root.optionIcon(modelData)
                        size: 18
                        color: segment.selected ? Theme.colors.onSecondaryContainer
                                                : Theme.colors.onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MdText {
                        role: "labelLarge"
                        text: root.optionText(modelData)
                        color: segment.selected ? Theme.colors.onSecondaryContainer
                                                : Theme.colors.onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // 分隔线：紧挨选中段的那条要藏起来（MD3 规范），否则会和胶囊边贴在一起
                readonly property bool prevSelected: index > 0
                        && root.currentValue === root.optionValue(root.model[index - 1])

                Rectangle {
                    visible: index > 0 && !segment.selected && !segment.prevSelected
                    width: 1
                    height: parent.height - 16
                    anchors.verticalCenter: parent.verticalCenter
                    x: -1
                    color: Theme.colors.outline
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const value = root.optionValue(modelData);
                        if (value !== root.currentValue) {
                            root.activated(value);
                        }
                    }
                }
            }
        }
    }
}
