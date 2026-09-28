#!/usr/bin/env sh

set -eu

here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
cleanup() {
    git worktree remove --force "${tmp}/base" >/dev/null 2>&1 || true
    rm -rf "${tmp}"
}
# shellcheck source=scripts/ci/cleanup.sh
. "${here}/cleanup.sh"

git worktree add --detach --quiet "${tmp}/base" "${1:-HEAD}"

snap() {
    "${here}/snapshot.sh" "$1"
    "${here}/probe.sh" "$1"
}

snap "${tmp}/base" >"${tmp}/before"
snap . >"${tmp}/after"
diff "${tmp}/before" "${tmp}/after"
