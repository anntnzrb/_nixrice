#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# RUNNER
# Script runner path
RUNNER="${1:-}"

# SCRIPT
# Script path
SCRIPT="${2:-}"

require_arg "${RUNNER}" "runner"
require_arg "${SCRIPT}" "script"

shift 2

run_exec "${RUNNER}" "${SCRIPT}" "$@"
