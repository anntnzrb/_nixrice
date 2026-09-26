#!/usr/bin/env sh
# Diffs machine, home and probe drvPaths between a git ref (default: HEAD) and
# the working tree. No output and exit 0 means the change is a pure refactor;
# inspect a changed pair with `nix run nixpkgs#nix-diff -- <old> <new>`.

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
