import QtQuick
import QtQuick.Controls
import QtQuick.Window
import HypsHub 1.0

/*
 * 布局自检：把目标页面挂到 1440x900 窗口里，遍历对象树，报告
 *   COLLAPSED  可见但尺寸为 0（内容被压没）
 *   OVERFLOW   绝对坐标超出窗口右/下边界（横向溢出）
 *   CLIPPED    Text 未省略也未换行，implicitWidth > width（文字被截断）
 *   NAN        几何量为 NaN
 * 用法: HYPS_AUDIT_PAGE=HomePage ./build/hyps-hub --qml-source qml/dev/LayoutAudit.qml --allow-root
 */
ApplicationWindow {
    id: win
    visible: true
    width: 1440
    height: 900
    color: Theme.colors.surface

    // 由同目录的 Audit<Page>.qml 覆盖（--qml-source 无法传自定义参数）
    property string pageName: "HomePage"

    // 几何转储模式：把每个可见控件的绝对坐标打出来（scripts/ui-geom.sh 用）
    property bool geomMode: false

    property Item emitHost: contentItem

    // console.* 在本进程不落到 stderr；用 createQmlObject 的失败信息把文本带出来
    property var findings: []
    property int findingIndex: 0

    // 只有「未捕获」的 createQmlObject 失败才会被引擎打到 stderr，
    // 所以一次调用只能带出一条：抛错即中断本次 handler，下一条由定时器再发。
    function emitOne(text) {
        Qt.createQmlObject('import QtQuick\nimport "MSG ' + text + '"\nItem {}',
                           emitHost, "e");
    }

    function report(text) {
        const list = findings.slice();
        // 通道是 import "<text>"，文本里不能再有引号/换行
        list.push(String(text).replace(/["'\n\r]/g, "'"));
        findings = list;
    }

    property int visibleCount: 0
    property int collapsedCount: 0
    property int overflowCount: 0
    property int clippedCount: 0
    property int nanCount: 0

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "../pages/" + win.pageName + ".qml"
        onStatusChanged: {
            if (status === Loader.Error) {
                win.report("LOAD_ERROR " + win.pageName);
                Qt.quit();
            }
        }
    }

    function isPopupTree(item) {
        // 弹窗类：有 closePolicy + contentItem，或祖先链上是这类对象
        let node = item;
        while (node) {
            if (node.closePolicy !== undefined && node.opened !== undefined) {
                return true;
            }
            node = node.parent;
        }
        return false;
    }

    function insideFlickable(item) {
        let node = item.parent;
        while (node) {
            const typeName = String(node);
            if (typeName.indexOf("Flickable") >= 0 || typeName.indexOf("ScrollView") >= 0
                    || typeName.indexOf("ListView") >= 0 || typeName.indexOf("GridView") >= 0) {
                return true;
            }
            node = node.parent;
        }
        return false;
    }

    function isTextItem(item) {
        return item.text !== undefined && item.elide !== undefined
                && item.wrapMode !== undefined;
    }

    // 收起的 MdExpansionPanel：祖先 clip 且高度为 0，属于预期状态
    function insideCollapsedClip(item) {
        let node = item.parent;
        while (node) {
            if (node.clip !== undefined && node.clip === true && node.height <= 0) {
                return true;
            }
            node = node.parent;
        }
        return false;
    }

    // Flickable 的 contentItem：宽度跟随 contentWidth，空文本时为 0 属正常
    function isFlickableContentItem(item) {
        const par = item.parent;
        return !!(par && par.contentItem !== undefined && par.contentItem === item);
    }

    function hasVisibleChild(item) {
        const kids = item.children;
        for (let i = 0; i < kids.length; ++i) {
            if (kids[i].visible !== undefined && kids[i].visible) {
                return true;
            }
        }
        return false;
    }

    function path(item) {
        const parts = [];
        let node = item;
        let guard = 0;
        while (node && guard < 8) {
            parts.unshift(String(node).replace(/\(0x[0-9a-f]+\)/, ""));
            node = node.parent;
            ++guard;
        }
        return parts.join(" > ");
    }

    function audit(item, depth) {
        if (!item || item.visible === undefined || !item.visible || item.opacity === 0) {
            return;
        }
        if (depth > 60) {
            return;
        }

        const w = item.width;
        const h = item.height;
        const x = item.x;
        const y = item.y;
        const bad = isNaN(w) || isNaN(h) || isNaN(x) || isNaN(y);
        if (bad) {
            ++win.nanCount;
            if (win.nanCount <= 6) {
                win.report("NAN " + path(item) + " x=" + x + " y=" + y
                             + " w=" + w + " h=" + h);
            }
        } else {
            ++win.visibleCount;

            const popup = isPopupTree(item);
            // 自身 clip 且高度为 0：收起状态的容器（MdExpansionPanel bodyWrapper），属预期
            const selfClipped = item.clip !== undefined && item.clip === true && h <= 0;
            const skip = popup || selfClipped || insideCollapsedClip(item)
                    || isFlickableContentItem(item);

            // 尺寸塌陷：可见、有可见子项、却为 0
            if (!skip && (w <= 0 || h <= 0) && hasVisibleChild(item)) {
                ++win.collapsedCount;
                if (win.collapsedCount <= 8) {
                    win.report("COLLAPSED " + path(item) + " w=" + w + " h=" + h);
                }
            }

            // 溢出窗口：只报不在 Flickable/Popup 里的项
            if (!skip && !insideFlickable(item)) {
                const topLeft = item.mapToItem(null, 0, 0);
                if (topLeft) {
                    const right = topLeft.x + w;
                    const bottom = topLeft.y + h;
                    if (right > win.width + 1 || bottom > win.height + 1
                            || topLeft.x < -1 || topLeft.y < -1) {
                        ++win.overflowCount;
                        if (win.overflowCount <= 8) {
                            win.report("OVERFLOW " + path(item)
                                         + " box=(" + Math.round(topLeft.x) + ","
                                         + Math.round(topLeft.y) + "," + Math.round(right)
                                         + "," + Math.round(bottom) + ") win="
                                         + win.width + "x" + win.height);
                        }
                    }
                }
            }

            // 文本截断
            if (!skip && isTextItem(item) && w > 0) {
                const noElide = item.elide === Text.ElideNone;
                const noWrap = item.wrapMode === Text.NoWrap;
                if (noElide && noWrap && item.implicitWidth > w + 1.5
                        && String(item.text).length > 0) {
                    ++win.clippedCount;
                    if (win.clippedCount <= 10) {
                        win.report("CLIPPED " + path(item)
                                     + " need=" + Math.round(item.implicitWidth)
                                     + " have=" + Math.round(w)
                                     + " text=\"" + String(item.text).slice(0, 40) + "\"");
                    }
                }
            }
        }

        if (win.geomMode && !isPopupTree(item)) {
            const typeName = String(item).replace(/\(0x[0-9a-f]+\)/, "").replace(/^.*\//, "");
            const interesting = typeName.indexOf("Md") >= 0 || item.text !== undefined
                    || item.accessibleName !== undefined;
            if (interesting && w > 0 && h > 0) {
                const tl = item.mapToItem(null, 0, 0);
                const label = item.text !== undefined ? String(item.text).slice(0, 22)
                            : (item.accessibleName !== undefined ? String(item.accessibleName).slice(0, 22) : "");
                win.report("GEOM|" + typeName + "|" + Math.round(tl.x) + "|" + Math.round(tl.y)
                             + "|" + Math.round(w) + "|" + Math.round(h) + "|" + label);
            }
        }

        const kids = item.children;
        for (let i = 0; i < kids.length; ++i) {
            audit(kids[i], depth + 1);
        }
    }

    function runAudit() {
        win.visibleCount = 0;
        win.collapsedCount = 0;
        win.overflowCount = 0;
        win.clippedCount = 0;
        win.nanCount = 0;
        if (pageLoader.item) {
            audit(pageLoader.item, 0);
        }
        win.report("SUMMARY " + win.pageName
                     + " visible=" + win.visibleCount
                     + " collapsed=" + win.collapsedCount
                     + " overflow=" + win.overflowCount
                     + " clipped=" + win.clippedCount
                     + " nan=" + win.nanCount);
        win.findingIndex = 0;
        emitTimer.start();
    }

    Component.onCompleted: Qt.callLater(function () {})

    // 给异步数据（Games/Tasks/Configs/EnvReport）留出加载时间
    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: win.runAudit()
    }

    Timer {
        id: emitTimer
        interval: 1
        repeat: true
        onTriggered: {
            if (win.findingIndex >= win.findings.length) {
                emitTimer.stop();
                Qt.quit();
                return;
            }
            const text = win.findings[win.findingIndex];
            win.findingIndex = win.findingIndex + 1;
            win.emitOne(text);
        }
    }
}
