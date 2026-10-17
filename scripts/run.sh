#!/usr/bin/env bash
# 构建（如需）并启动 Hyps Hub
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"

if [ ! -x "$BUILD_DIR/hyps-hub" ]; then
    "$ROOT/scripts/build.sh"
fi

exec "$BUILD_DIR/hyps-hub" "$@"
