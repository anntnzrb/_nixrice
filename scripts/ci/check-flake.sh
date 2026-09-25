#!/usr/bin/env sh
# shellcheck disable=SC2312

set -eu

nix run --option eval-cache false --no-write-lock-file --inputs-from path:. nixpkgs#flake-checker -- \
    --check-outdated --check-owner --check-supported --fail-mode --no-telemetry \
    --nixpkgs-keys nixpkgs,nixpkgs-unstable

# every machine and standalone home must evaluate on every CI platform
"$(dirname "$0")/snapshot.sh"

nix fmt --option eval-cache false --no-write-lock-file -- --check

if test "$(uname -s)" = Linux; then
    nix flake check --option eval-cache false --no-write-lock-file path:. \
        --all-systems --no-build
fi

nix flake check --option eval-cache false --no-write-lock-file path:. \
    --print-build-logs
