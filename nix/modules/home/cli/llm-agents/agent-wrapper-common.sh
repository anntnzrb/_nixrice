#!/bin/sh

# EXIT_MISSING_DIR
# Exit code for missing directory
EXIT_MISSING_DIR="1"

# EXIT_MISSING_ARG
# Exit code for missing argument
EXIT_MISSING_ARG="2"

# DEFAULT_VERSION
# Default version for js runner packages
DEFAULT_VERSION="latest"

# AGENTS_HOME
# Root of agents repo
AGENTS_HOME="${HOME}/.config/agents"

# SYNC
# Sync script path
SYNC="${AGENTS_HOME}/bin/sync.rs"

# die
# Emit error and exit
die() {
    msg="${1}"
    code="${2:-1}"
    printf '%s\n' "llm-agent: ${msg}" >&2
    exit "${code}"
}

# require_arg
# Require non empty arg
require_arg() {
    value="${1}"
    label="${2}"
    [ -n "${value}" ] || die "missing ${label}" "${EXIT_MISSING_ARG}"
    return 0
}

# require_dir
# Require directory to exist
require_dir() {
    path="${1}"
    [ -d "${path}" ] || die "missing agents dir: ${path}" "${EXIT_MISSING_DIR}"
    return 0
}

# run_sync
# Run sync after checking agents dir
run_sync() {
    require_dir "${AGENTS_HOME}"
    "${SYNC}"
    return 0
}

# parse_version
# Parse --version0 flags and emit version
parse_version() {
    version="${DEFAULT_VERSION}"
    while [ $# -gt 0 ]; do
        case "$1" in
            --version0)
                if [ $# -ge 2 ] && [ -n "${2-}" ] && [ "${2#-}" = "$2" ]; then
                    version="$2"
                    shift 2
                    continue
                fi
                break
                ;;
            --version0=*)
                version="${1#*=}"
                shift
                continue
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done
    printf '%s\n' "${version}"
}

# run_exec
# Run sync then exec command
run_exec() {
    run_sync
    exec "$@"
}
