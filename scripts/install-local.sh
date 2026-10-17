#!/usr/bin/env bash
# 安装到 ~/.local（不需要 root），不修改任何用户数据目录
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
PREFIX="${PREFIX:-$HOME/.local}"

cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
cmake --build "$BUILD_DIR"

cmake --install "$BUILD_DIR" --prefix "$PREFIX"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$PREFIX/share/applications" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 || true
fi

cat <<MSG

已安装到 $PREFIX：
  $PREFIX/bin/hyps-hub
  $PREFIX/share/applications/hyps-hub.desktop
  $PREFIX/share/icons/hicolor/scalable/apps/hyps-hub.svg

如果 $PREFIX/bin 不在 PATH 中，请自行加入。
卸载：scripts/uninstall-local.sh
用户数据（运行副本/配置/日志）不会被删除。
MSG
