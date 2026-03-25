#!/bin/sh
set -eu

# DEFAULT_VERSION
# Default version for npm packages. Empty means resolve unpinned latest-ish package name via bun x
DEFAULT_VERSION="latest"

# BUN
# Bun executable path
BUN="${1:-}"

# PACKAGE
# npm package name
PACKAGE="${2:-}"

require_arg() {
    value="${1}"
    label="${2}"
    [ -n "${value}" ] || {
        printf '%s\n' "llm-agent: missing ${label}" >&2
        exit 2
    }
    return 0
}

require_arg "${BUN}" "bun"
require_arg "${PACKAGE}" "package"

shift 2

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

exec "${BUN}" x "${PACKAGE_SPEC}" "$@"
