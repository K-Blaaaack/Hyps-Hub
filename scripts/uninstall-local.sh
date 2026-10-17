#!/usr/bin/env bash
# 仅删除本地安装的程序文件；绝不删除运行副本、配置、日志与缓存
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"

case "$PREFIX" in
    "$HOME"/*) ;;
    *)
        echo "拒绝操作不安全的 PREFIX：$PREFIX（应为 \$HOME 下的目录）" >&2
        exit 1
        ;;
esac

rm -f -- "$PREFIX/bin/hyps-hub"
rm -f -- "$PREFIX/share/applications/hyps-hub.desktop"
rm -f -- "$PREFIX/share/icons/hicolor/scalable/apps/hyps-hub.svg"
rm -rf -- "$PREFIX/share/doc/hyps-hub"
rm -rf -- "$PREFIX/share/licenses/hyps-hub"

echo "已删除 $PREFIX 下的 Hyps Hub 程序文件。"
echo "保留用户数据："
echo "  ${XDG_DATA_HOME:-$HOME/.local/share}/hyps-hub"
echo "  ${XDG_CONFIG_HOME:-$HOME/.config}/hyps-hub"
echo "  ${XDG_STATE_HOME:-$HOME/.local/state}/hyps-hub"
