#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# BUN
# Bun executable path
BUN="${1:-}"

# SYNC_SCRIPT
# Sync script path
SYNC_SCRIPT_ARG="${2:-}"

# PACKAGE
# npm package name
PACKAGE="${3:-}"

require_arg "${BUN}" "bun"
set_sync_command "${BUN}" "${SYNC_SCRIPT_ARG}"
require_arg "${PACKAGE}" "package"

shift 3

try_sync

exec "${BUN}" x "${PACKAGE}" "$@"
