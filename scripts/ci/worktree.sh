# shellcheck shell=sh
# Sourced: checks out ${1:-HEAD} at ${tmp}/base and removes it on exit.

here="$(cd "$(dirname "$0")" && pwd)"

tmp="$(mktemp -d)"
cleanup() {
    git worktree remove --force "${tmp}/base" >/dev/null 2>&1 || true
    rm -rf "${tmp}"
}
# shellcheck source=scripts/ci/cleanup.sh
. "${here}/cleanup.sh"

git worktree add --detach --quiet "${tmp}/base" "${1:-HEAD}"
