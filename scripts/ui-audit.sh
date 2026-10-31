#!/usr/bin/env bash
# 界面自检：几何审计 + 运行时警告门禁。
#
#   scripts/ui-audit.sh [fixture-dir]
#
# 1) 用 qml/dev/LayoutAudit.qml 遍历每页对象树，报告
#    COLLAPSED（可见却 0 尺寸）/ OVERFLOW（超出窗口）/ CLIPPED（文本被截断）/ NAN；
#    在 1440x900 与最小窗口 1040x720 两种尺寸下各跑一遍。
# 2) 用真实 qrc 构建逐页离屏渲染，门禁任何 QML 运行时警告。
#
# 不传 fixture-dir 时在 /tmp 下自建一份隔离夹具（不碰用户真实配置）。
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

BASE="${1:-}"
if [ -z "$BASE" ]; then
    BASE="$(mktemp -d /tmp/hyps-ui-audit.XXXXXX)"
    bash scripts/ui-fixture.sh "$BASE" >/dev/null 2>&1
fi

BIN=./build/hyps-hub
if [ ! -x "$BIN" ]; then
    echo "缺少可执行文件：先执行 cmake --build build --target hyps-hub"
    exit 1
fi

PAGES=(HomePage GamesPage TasksPage ConfigPage DiagnosticsPage SettingsPage AboutPage OnboardingPage)
SLUGS=(home games tasks config diagnostics settings about)

export QT_QPA_PLATFORM=offscreen
export QT_QUICK_BACKEND=software
export XDG_CONFIG_HOME="$BASE/config"
export XDG_DATA_HOME="$BASE/data"
export XDG_STATE_HOME="$BASE/state"
export XDG_CACHE_HOME="$BASE/cache"

fail=0

# 本进程吞掉 QML 的 console.*，审计结果通过「未捕获的 createQmlObject 失败」带出来，
# 每条以 MSG 开头、以 ": no such directory 收尾。
parse() { grep -oP 'MSG \K.*?(?=": no such)' | sed -E "s/_QMLTYPE_[0-9]+//g"; }

echo "== 1/2 几何审计（对象树遍历）=="
for size in "Audit:1440x900" "AuditNarrow:1040x720"; do
    prefix="${size%%:*}"; label="${size##*:}"
    for page in "${PAGES[@]}"; do
        wrapper="qml/dev/${prefix}${page}.qml"
        [ -f "$wrapper" ] || { echo "  缺少 $wrapper"; fail=1; continue; }
        out="$(timeout 60 "$BIN" --qml-source "$wrapper" --allow-root 2>&1 | parse)"
        summary="$(echo "$out" | grep '^SUMMARY' | head -1)"
        problems="$(echo "$out" | grep -vE '^SUMMARY' | wc -l)"
        if [ "$problems" -ne 0 ]; then
            fail=1
            echo "  FAIL $label $page"
            echo "$out" | grep -vE '^SUMMARY' | sed 's/^/       /' | head -6
        else
            echo "  ok   $label $page  ${summary#SUMMARY }"
        fi
    done
done

echo "== 2/2 运行时警告门禁（qrc 构建逐页渲染）=="
pat='QML 警告|TypeError|ReferenceError|Unable to assign|Cannot assign|Non-existent|Binding loop'
for i in "${!SLUGS[@]}"; do
    slug="${SLUGS[$i]}"
    python3 - "$BASE" "$slug" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1]) / "config/hyps-hub/config.json"
d = json.loads(p.read_text())
d["lastPage"] = sys.argv[2]
d["window"] = {"height": 900, "width": 1440, "x": 0, "y": 0, "maximized": False}
p.write_text(json.dumps(d))
PY
    out="$(timeout 60 "$BIN" --screenshot "/tmp/hyps-audit-$slug.png" --allow-root 2>&1)"
    hits="$(echo "$out" | grep -cE "$pat")"
    if [ "$hits" -ne 0 ]; then
        fail=1
        echo "  FAIL $slug（$hits 条警告）"
        echo "$out" | grep -E "$pat" | head -3 | sed 's/^/       /'
    else
        echo "  ok   $slug 无警告"
    fi
done

echo
if [ "$fail" -eq 0 ]; then
    echo "PASS 界面自检全部通过"
else
    echo "FAIL 界面自检发现问题"
fi
exit "$fail"
