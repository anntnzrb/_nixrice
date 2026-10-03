#!/usr/bin/env sh

set -eu

root="${1:-.}"
tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
# shellcheck source=scripts/ci/cleanup.sh
. "${root}/scripts/ci/cleanup.sh"

"${root}/scripts/ci/probe.sh" "${root}" "${2:-}" >"${tmp}/probes"

awk '{ print $1 }' "${tmp}/probes" >"${tmp}/ran"
grep -Fx -f "${tmp}/ran" "${root}/tests/probe-errors.txt" >"${tmp}/expected" || true
awk '$2 == "eval-error" { print $1 }' "${tmp}/probes" | diff -u "${tmp}/expected" -
