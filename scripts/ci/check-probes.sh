#!/usr/bin/env sh
# Imports every feature and profile into its probe host (probe.sh) and fails
# when the set that does not evaluate differs from tests/probe-errors.txt:
# a feature broke, or an expected failure went away (then update the list).
# Honours PROBE_SHARD / PROBE_SHARDS, comparing only that shard's probes.

set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
# shellcheck source=scripts/ci/cleanup.sh
. "${root}/scripts/ci/cleanup.sh"

"${root}/scripts/ci/probe.sh" "${1:-.}" >"${tmp}/probes"

# expected errors among the probes this shard ran
awk '{ print $1 }' "${tmp}/probes" >"${tmp}/ran"
grep -Fx -f "${tmp}/ran" "${root}/tests/probe-errors.txt" >"${tmp}/expected" || true
awk '$2 == "eval-error" { print $1 }' "${tmp}/probes" | diff -u "${tmp}/expected" -
