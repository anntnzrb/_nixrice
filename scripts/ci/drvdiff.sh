#!/usr/bin/env sh

set -eu

# shellcheck source=scripts/ci/worktree.sh
. "$(dirname "$0")/worktree.sh"

snap() {
    "${here}/snapshot.sh" "$1"
    "${here}/probe.sh" "$1"
}

snap "${tmp}/base" >"${tmp}/before"
snap . >"${tmp}/after"
diff "${tmp}/before" "${tmp}/after"
