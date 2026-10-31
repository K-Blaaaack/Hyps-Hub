#!/usr/bin/env bash
# 开发模式启动器：从磁盘加载 QML，改界面不用重新编译。
#
#   scripts/dev-run.sh                # 前台跑，Ctrl-C 退出
#   scripts/dev-run.sh --bg           # 后台跑，日志写 /tmp/hyps-dev.log
#   scripts/dev-run.sh --once         # 只启动一次，不监视文件
#
# 行为：
#   - 启动 `build/hyps-hub --qml-source qml/Main.qml`（QML 走磁盘，改完即生效）
#   - 监视 qml/ 变动 → 自动重启进程（600ms 去抖，避免编辑器连写多次触发）
#   - 监视 src/、assets/ 与 CMakeLists.txt 变动 → 先增量编译，编译通过再重启
#   - 编译失败或 QML 加载失败时**保留旧进程不动**，错误打在日志里
#
# 首次使用前需要一份可用的构建：cmake -S . -B build && cmake --build build
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

BIN=./build/hyps-hub
LOG="${HYPS_DEV_LOG:-/tmp/hyps-dev.log}"
MODE="foreground"
ONCE=0

for arg in "$@"; do
    case "$arg" in
        --bg) MODE="background" ;;
        --once) ONCE=1 ;;
        --stop)
            # 先杀启动器：它有 trap，会连带停掉应用
            if [ -f /tmp/hyps-dev.pid ]; then
                kill "$(cat /tmp/hyps-dev.pid)" 2>/dev/null
                rm -f /tmp/hyps-dev.pid
            fi
            # 兜底按进程名精确匹配。不能用 pkill -f "hyps-hub --qml-source"：
            # 那串会命中调用方的 bash -c 命令行，把自己也杀掉。
            pkill -x hyps-hub 2>/dev/null
            echo "[dev] 已停止"
            exit 0
            ;;
        -h|--help) sed -n '2,20p' "$0" | grep '^#' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "未知参数：$arg"; exit 2 ;;
    esac
done

if [ ! -x "$BIN" ]; then
    echo "找不到 $BIN，先构建："
    echo "  cmake -S . -B build && cmake --build build --target hyps-hub"
    exit 1
fi

PID=""

build_if_needed() {
    local stale
    # assets/ 也要看：SVG 是编进 qrc 的，光改文件不重编不会生效
    stale=$(find src assets CMakeLists.txt -newer "$BIN" -print -quit 2>/dev/null)
    if [ -n "$stale" ]; then
        echo "[dev] 源码有变动，增量编译…"
        if ! cmake --build build --target hyps-hub 2>&1 | tail -3; then
            echo "[dev] 编译失败，保持当前进程"
            return 1
        fi
    fi
    return 0
}

start() {
    stop
    if ! build_if_needed; then
        return 1
    fi
    echo "[dev] 启动 $(date +%H:%M:%S)  →  $BIN --qml-source qml/Main.qml"
    "$BIN" --qml-source qml/Main.qml >>"$LOG" 2>&1 &
    PID=$!
    sleep 0.6
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "[dev] 启动失败，日志尾部："
        tail -20 "$LOG"
        PID=""
        return 1
    fi
    echo "[dev] pid=$PID  日志：$LOG"
}

stop() {
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        wait "$PID" 2>/dev/null
    fi
    PID=""
}

cleanup() {
    echo
    echo "[dev] 退出"
    stop
    # 收掉自己的子进程：inotifywait 是 while 循环的前台子进程，
    # 启动器退出时它不会跟着死，会变成孤儿一直占着 watch。
    pkill -P $$ 2>/dev/null
    exit 0
}
trap cleanup INT TERM

mkdir -p "$(dirname "$LOG")"
: >"$LOG"

if [ "$MODE" = "background" ]; then
    echo "[dev] 后台模式：日志 $LOG，停止用 scripts/dev-run.sh --stop"
    nohup "$0" >/dev/null 2>&1 &
    echo $! >/tmp/hyps-dev.pid
    echo "[dev] 启动器 pid=$(cat /tmp/hyps-dev.pid)"
    exit 0
fi

start || exit 1

if [ "$ONCE" -eq 1 ]; then
    echo "[dev] --once：不监视文件，前台运行，Ctrl-C 退出"
    wait "$PID"
    exit 0
fi

echo "[dev] 监视 qml/ src/ assets/ CMakeLists.txt（改完自动重启，Ctrl-C 退出）"
# inotifywait 在编辑器「写临时文件再改名」时会给多次事件，去抖后再重启。
# 用 -t 2 让 inotifywait 每 2 秒无条件返回一次：前台阻塞在 inotifywait 上时
# bash 会把 SIGTERM 的 trap 一直压着（要等当前命令结束），--stop 就杀不掉进程，
# 还会留下孤儿监视器。定时返回让 trap 最迟 2 秒内生效。
while :; do
    if inotifywait -q -r -t 2 -e close_write,create,delete,move \
            qml src assets CMakeLists.txt >/dev/null 2>&1; then
        sleep 0.6
        # 排空同一批里剩下的事件，避免连续重启
        inotifywait -q -r -t 1 -e close_write,create,delete,move qml src assets CMakeLists.txt >/dev/null 2>&1
        start
    fi
done
