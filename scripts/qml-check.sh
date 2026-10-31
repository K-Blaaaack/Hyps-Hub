#!/usr/bin/env bash
# QML 单文件自检：qmllint + 真实加载（离屏）+ 截图 + 像素摘要。
#
# 用法：
#   scripts/qml-check.sh qml/components/MdButton.qml
#   scripts/qml-check.sh qml/dev/MdButtonGallery.qml --shot
#
# 退出码非 0 表示有 QML 警告、加载失败或（--shot 时）截图空白。
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/build/hyps-hub"
FILE="${1:?用法: qml-check.sh <file.qml> [--shot]}"
WANT_SHOT=0
[ "${2:-}" = "--shot" ] && WANT_SHOT=1

[ -f "$FILE" ] || { echo "FAIL 找不到文件：$FILE"; exit 2; }
[ -x "$BIN" ] || { echo "FAIL 缺少可执行文件 $BIN（先跑 scripts/build.sh）"; exit 2; }

BASE="$(mktemp -d "${TMPDIR:-/tmp}/md3-check.XXXXXX")"
trap 'rm -rf "$BASE"' EXIT
"$ROOT/scripts/ui-fixture.sh" "$BASE" >/dev/null

STATUS=0

echo "=== qmllint: $FILE"
LINT_OUT="$(qmllint -I "$ROOT/qml" "$FILE" 2>&1 || true)"
# HypsHub 是 C++ 注册的模块，qmllint 看不到，过滤这类噪音。
LINT_REAL="$(printf '%s\n' "$LINT_OUT" | grep -v -E 'HypsHub|^Warning: .*import|Failed to import|^$' || true)"
if [ -n "$LINT_REAL" ]; then
    echo "$LINT_REAL"
    STATUS=1
else
    echo "OK（无语法/类型问题）"
fi

run_binary() { # args...
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    XDG_CONFIG_HOME="$BASE/config" XDG_DATA_HOME="$BASE/data" \
    XDG_STATE_HOME="$BASE/state" XDG_CACHE_HOME="$BASE/cache" \
    timeout 45 "$BIN" "$@" 2>>"$BASE/stderr.log" >/dev/null
    echo $?
}

echo "=== 加载: $FILE"
SHOT="$BASE/shot.png"
CODE="$(run_binary --screenshot "$SHOT" --allow-root --qml-source "$FILE")"
if [ "$CODE" = "4" ]; then
    # 根对象不是 Window，无法截图，退回冒烟加载
    CODE="$(run_binary --smoke-test --allow-root --qml-source "$FILE")"
    WANT_SHOT=0
fi

if [ "$CODE" != "0" ]; then
    echo "FAIL 加载失败（exit=$CODE）"
    STATUS=1
fi

echo "=== 运行时输出"
if [ -s "$BASE/stderr.log" ]; then
    grep -v -E '^\s*$' "$BASE/stderr.log" | head -60
    if grep -q -E 'QML 警告|TypeError|ReferenceError|is not defined|Unable to assign|Cannot assign|Non-existent|Error:|Cannot read property|undefined is not' "$BASE/stderr.log"; then
        echo "FAIL 运行时存在 QML 错误/警告"
        STATUS=1
    fi
else
    echo "OK（stderr 为空）"
fi

if [ "$WANT_SHOT" = 1 ] && [ -f "$SHOT" ]; then
    echo "=== 截图摘要"
    python3 - "$SHOT" <<'PY'
import sys
from PIL import Image
from collections import Counter

img = Image.open(sys.argv[1]).convert("RGB")
w, h = img.size
small = img.resize((max(1, w // 4), max(1, h // 4)))
colors = Counter(small.getdata())
total = sum(colors.values())
top = colors.most_common(8)
print(f"size={w}x{h} 唯一色={len(colors)}")
for c, n in top:
    print(f"  #{c[0]:02x}{c[1]:02x}{c[2]:02x} {100.0 * n / total:5.1f}%")
dominant, dn = top[0]
if dn / total > 0.985:
    print(f"FAIL 画面几乎单色（#{dominant[0]:02x}{dominant[1]:02x}{dominant[2]:02x}），疑似空白")
    sys.exit(1)
print("OK 画面有内容")
PY
    [ $? -ne 0 ] && STATUS=1
fi

if [ "$STATUS" = 0 ]; then
    echo "PASS $FILE"
else
    echo "FAIL $FILE"
fi
exit $STATUS
