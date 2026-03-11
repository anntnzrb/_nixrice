#!/bin/sh

# EXIT_MISSING_DIR
# Exit code for missing directory
EXIT_MISSING_DIR="1"

# EXIT_MISSING_ARG
# Exit code for missing argument
EXIT_MISSING_ARG="2"

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

# run_exec
# Run sync then exec command
run_exec() {
    run_sync
    exec "$@"
}
