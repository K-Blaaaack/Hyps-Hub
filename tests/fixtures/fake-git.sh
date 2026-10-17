#!/usr/bin/env bash
# 测试用假 git：只实现 RuntimeManager 需要的最小行为，并记录调用参数。
set -u

log="${FAKE_GIT_LOG:-/dev/null}"
printf '%s\n' "$*" >> "$log"

if [ "${1:-}" = "-C" ]; then
    shift
    repo="${1:-}"
    shift || true
    cmd="${1:-}"
    shift || true
    case "$cmd" in
        log)
            if [ "${1:-}" = "-1" ]; then
                printf '%s\x1f%s\x1f%s\x1f%s\n' \
                    "${FAKE_GIT_COMMIT:-0123456789abcdef0123456789abcdef01234567}" \
                    "${FAKE_GIT_SHORT:-0123456789ab}" \
                    "test commit subject" \
                    "2026-01-01T00:00:00Z"
            fi
            ;;
        rev-parse)
            if [ "${1:-}" = "--verify" ]; then
                exit 0
            fi
            printf 'main\n'
            ;;
        status)
            if [ -n "${FAKE_GIT_DIRTY:-}" ]; then
                printf ' M config.conf\n'
            fi
            ;;
        fetch)
            printf 'fetched\n'
            ;;
        rev-list)
            printf '%s\t%s\n' "${FAKE_GIT_AHEAD:-0}" "${FAKE_GIT_BEHIND:-0}"
            ;;
        merge)
            if [ -n "${FAKE_GIT_MERGE_FAIL:-}" ]; then
                printf 'fatal: not possible to fast-forward\n' >&2
                exit 128
            fi
            printf 'Fast-forward\n'
            ;;
        *)
            ;;
    esac
    exit 0
fi

if [ "${1:-}" = "clone" ]; then
    target="${@: -1}"
    if [ -n "${FAKE_GIT_CLONE_FAIL:-}" ]; then
        printf 'remote: fatal: could not read from remote repository\n' >&2
        exit 128
    fi
    if [ -n "${FAKE_GIT_CLONE_HANG:-}" ]; then
        sleep 30
    fi
    mkdir -p "$target/scripts" "$target/lib" "$target/config/games.examples" "$target/config/runners"
    printf '#!/usr/bin/env bash\necho help\n' > "$target/scripts/_Hyps"
    printf '#!/usr/bin/env bash\ntrue\n' > "$target/init.sh"
    printf 'x\n' > "$target/lib/libs.sh"
    printf 'x\n' > "$target/lib/common.sh"
    printf 'path.config = "./config"\n' > "$target/config.conf"
    printf 'x\n' > "$target/config/games.examples/_common.example.conf"
    printf 'remote: Enumerating objects: 12, done.\nReceiving objects:  40%%\rReceiving objects: 100%% (12/12), 8.0 KiB, done.\nResolving deltas: 100%% (1/1), done.\n' >&2
    exit 0
fi

if [ "${1:-}" = "ls-remote" ]; then
    printf '0123456789abcdef0123456789abcdef01234567\tHEAD\n'
    exit 0
fi

printf 'fake git: unsupported args: %s\n' "$*" >&2
exit 2
