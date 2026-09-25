#!/usr/bin/env sh
# Imports every feature and profile into its probe host (probe.sh) and fails
# when the set that does not evaluate differs from tests/probe-errors.txt:
# a feature broke, or an expected failure went away (then update the list).

set -eu

root="$(cd "$(dirname "$0")/../.." && pwd)"

"${root}/scripts/ci/probe.sh" "${1:-.}" \
    | awk '$2 == "eval-error" { print $1 }' \
    | diff -u "${root}/tests/probe-errors.txt" -
