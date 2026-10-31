#!/usr/bin/env bash
# 几何转储：把某个页面所有可见控件的绝对 x/y/w/h 打出来，用于像素级对轨。
# 用法: scripts/ui-geom.sh ConfigPage > /tmp/geom-config.txt
set -uo pipefail
cd "$(dirname "$0")/.."
page="${1:?用法: ui-geom.sh <PageName>}"
tmp="qml/dev/Geom${page}.qml"
cat > "$tmp" <<EOF
import QtQuick
LayoutAudit { pageName: "${page}"; geomMode: true }
EOF
trap 'rm -f "$tmp"' EXIT
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
XDG_CONFIG_HOME=${GEOM_CONFIG:-/tmp/md3-final/config} \
XDG_DATA_HOME=${GEOM_DATA:-/tmp/md3-final/data} \
XDG_STATE_HOME=${GEOM_STATE:-/tmp/md3-final/state} \
XDG_CACHE_HOME=${GEOM_CACHE:-/tmp/md3-final/cache} \
timeout 60 ./build/hyps-hub --qml-source "$tmp" --allow-root 2>&1 \
  | grep -o 'GEOM|[^"]*' | sed 's/^GEOM|//' | sort -t'|' -k3,3n -k2,2n
