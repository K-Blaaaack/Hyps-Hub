#!/usr/bin/env bash
# 准备一份完全隔离的 XDG 夹具环境，供 UI 截图/自检使用（不读写用户真实配置）。
# 用法：scripts/ui-fixture.sh <base-dir>
set -euo pipefail

BASE="${1:?用法: ui-fixture.sh <base-dir>}"
CFG="$BASE/config"
DATA="$BASE/data"
STATE="$BASE/state"
CACHE="$BASE/cache"
FIX="$DATA/hyps-hub/runtime/Hyps"

mkdir -p "$CFG/hyps-hub/hyps/games" "$CFG/hyps-hub/hyps/runners" \
         "$STATE" "$CACHE/hyps-hub" \
         "$FIX/scripts" "$FIX/lib" "$FIX/config/games"

# ---- 组件夹具：让 Runtime 判定 ready ----
: > "$FIX/config.conf"
printf '#!/bin/sh\nexit 0\n' > "$FIX/init.sh"
printf '#!/bin/sh\necho "fixture _Hyps $*"\n' > "$FIX/scripts/_Hyps"
: > "$FIX/lib/libs.sh"
: > "$FIX/lib/common.sh"
chmod +x "$FIX/init.sh" "$FIX/scripts/_Hyps"

cat > "$FIX/config/games/_common.conf" <<'EOF'
[mangohud]
enabled = false
[gamemode]
wrapper_enabled = false
ld_preload_enabled = false
EOF

if [ ! -d "$FIX/.git" ]; then
    git -C "$FIX" init -q
    git -C "$FIX" -c user.email=ui@review -c user.name=ui-review add -A
    git -C "$FIX" -c user.email=ui@review -c user.name=ui-review commit -qm "fixture"
fi

cat > "$CFG/hyps-hub/hyps/games/_common.conf" <<'EOF'
# UI fixture
[mangohud]
enabled = false
[gamemode]
wrapper_enabled = false
ld_preload_enabled = false
[prepare]
kill_wineserver = false
[features]
fps_limit = 60
EOF

cat > "$CFG/hyps-hub/hyps/games/arknights.conf" <<'EOF'
[game]
exe = /path/to/Arknights Game/Arknights.exe
args = -dx12
[runner]
name = umu-dwproton
EOF

cat > "$CFG/hyps-hub/hyps/runners/umu-dwproton.conf" <<'EOF'
[proton]
path = /path/to/dwproton
EOF

cat > "$CFG/hyps-hub/config.json" <<'EOF'
{"advancedMode":false,"lastPage":"home","notificationsEnabled":true,"theme":"dark","version":1,"window":{"height":900,"width":1440,"x":0,"y":0,"maximized":false}}
EOF

echo "fixture ready: $BASE"
