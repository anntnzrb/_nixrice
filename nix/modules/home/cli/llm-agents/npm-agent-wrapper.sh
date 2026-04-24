#!/bin/sh
set -eu

# SCRIPT_DIR
# Wrapper directory
SCRIPT_DIR="${0%/*}"

# shellcheck source=agent-wrapper-common.sh
. "${SCRIPT_DIR}/agent-wrapper-common.sh"

# DEFAULT_VERSION
# Default version for npm packages. Empty means resolve unpinned latest-ish package name via bun x
DEFAULT_VERSION="latest"

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

VERSION="${DEFAULT_VERSION}"
while [ $# -gt 0 ]; do
    case "$1" in
        --version0)
            if [ $# -ge 2 ] && [ -n "${2-}" ] && [ "${2#-}" = "$2" ]; then
                VERSION="$2"
                shift 2
                continue
            fi
            break
            ;;
        --version0=*)
            VERSION="${1#*=}"
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

PACKAGE_SPEC="${PACKAGE}"
[ -n "${VERSION}" ] && PACKAGE_SPEC="${PACKAGE}@${VERSION}"

try_sync

exec "${BUN}" x "${PACKAGE_SPEC}" "$@"
