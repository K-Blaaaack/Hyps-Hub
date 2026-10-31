#!/usr/bin/env bash
# 从 CHANGELOG.md 抽出指定版本的段落，作为 GitHub Release 的正文。
#
#   scripts/release-notes.sh 0.4.0     # 打印到 stdout
#   scripts/release-notes.sh v0.4.0    # 带 v 的写法也认
#
# 找不到该版本的段落时以非零码退出（发布流程据此直接失败，
# 避免发出一个正文空白的 release）。
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

ver="${1:-}"
if [ -z "$ver" ]; then
    echo "用法：$0 <版本号>（例：$0 0.4.0）" >&2
    exit 2
fi
ver="${ver#v}"

if [ ! -f CHANGELOG.md ]; then
    echo "找不到 CHANGELOG.md" >&2
    exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk -v ver="$ver" '
    # 版本标题形如 "## [0.4.0] — 2026-10-31"
    $0 ~ "^## \\[" ver "\\]" { inside = 1; next }
    # 遇到下一个版本标题就停，避免把后续版本写进来
    inside && /^## \[/ { exit }
    inside { lines[++n] = $0 }
    END {
        # 去掉首尾空行，以及版本之间的 --- 分隔线
        start = 1
        while (start <= n && lines[start] ~ /^[[:space:]]*$/) start++
        while (n >= start && (lines[n] ~ /^[[:space:]]*$/ || lines[n] == "---")) n--
        for (i = start; i <= n; i++) print lines[i]
    }
' CHANGELOG.md > "$tmp"

if [ ! -s "$tmp" ]; then
    echo "CHANGELOG.md 里没有 ${ver} 的段落：先补记录再发版。" >&2
    echo "期望的标题格式：## [${ver}] — YYYY-MM-DD" >&2
    exit 1
fi

# 用 cat 而不是把内容塞进变量再 echo：调用方用 head 提前关管道时，
# bash 内建会报 "断开的管道"，cat 只会静默退出。
cat "$tmp"
