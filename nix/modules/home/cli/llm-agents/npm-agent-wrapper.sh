#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# BUN
# Bun executable used to run the sync script
BUN="${1:-}"

# SYNC_SCRIPT
# Sync script path
SYNC_SCRIPT_ARG="${2:-}"

# TOOL
# Agent tool name used for the npm cache
TOOL="${3:-}"

# PACKAGE
# npm package name
PACKAGE="${4:-}"

# BIN
# Binary name exposed by the npm package
BIN="${5:-}"

require_arg "${BUN}" "bun"
set_sync_command "${BUN}" "${SYNC_SCRIPT_ARG}"
require_arg "${TOOL}" "tool"
require_arg "${PACKAGE}" "package"
require_arg "${BIN}" "bin"

shift 5

run_npm_package "${TOOL}" "${PACKAGE}" "${BIN}" latest -- "$@"
