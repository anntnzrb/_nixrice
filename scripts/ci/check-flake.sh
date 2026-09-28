#!/usr/bin/env sh
# shellcheck disable=SC2312

set -eu

nix run --option eval-cache false --no-write-lock-file --inputs-from path:. nixpkgs#flake-checker -- \
    --check-owner --check-supported --fail-mode --no-telemetry \
    --nixpkgs-keys nixpkgs,nixpkgs-unstable

"$(dirname "$0")/snapshot.sh" . darwin home >/dev/null

check() {
    nix flake check --option eval-cache false --no-write-lock-file \
        --option allow-import-from-derivation false \
        --print-build-logs "$@" path:.
}

if test "$(uname -s)" = Linux; then
    check --all-systems --no-build
fi
check

nix develop --option eval-cache false --no-write-lock-file path:. \
    -c clan vars check
