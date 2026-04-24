#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# SYNC_RUNNER_ARG
# Sync runner path
SYNC_RUNNER_ARG="${1:-}"

# SYNC_SCRIPT_ARG
# Sync script path
SYNC_SCRIPT_ARG="${2:-}"

# RUNNER
# Script runner path
RUNNER="${3:-}"

# SCRIPT
# Script path
SCRIPT="${4:-}"

set_sync_command "${SYNC_RUNNER_ARG}" "${SYNC_SCRIPT_ARG}"
require_arg "${RUNNER}" "runner"
require_arg "${SCRIPT}" "script"

shift 4

run_exec "${RUNNER}" "${SCRIPT}" "$@"
