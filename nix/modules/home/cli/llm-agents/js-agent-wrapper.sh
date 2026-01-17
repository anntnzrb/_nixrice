#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# BUN
# JS runner path
BUN="${1:-}"

# PACKAGE
# Package to execute
PACKAGE="${2:-}"

require_arg "${BUN}" "bun"
require_arg "${PACKAGE}" "package"

shift 2

VERSION="$(parse_version "$@")"

run_exec "${BUN}" x "${PACKAGE}@${VERSION}" "$@"
