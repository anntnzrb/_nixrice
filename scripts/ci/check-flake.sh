#!/usr/bin/env sh
# shellcheck disable=SC2312

set -eu

# nixpkgs freshness is left to Dependabot: an age limit here would fail every
# unrelated PR once nixpkgs is a month old
nix run --option eval-cache false --no-write-lock-file --inputs-from path:. nixpkgs#flake-checker -- \
    --check-owner --check-supported --fail-mode --no-telemetry \
    --nixpkgs-keys nixpkgs,nixpkgs-unstable

# every machine and standalone home must evaluate on every CI platform;
# formatting, lint and tests/ run as flake checks below
"$(dirname "$0")/snapshot.sh"

if test "$(uname -s)" = Linux; then
    nix flake check --option eval-cache false --no-write-lock-file path:. \
        --all-systems --no-build
fi

nix flake check --option eval-cache false --no-write-lock-file path:. \
    --print-build-logs
