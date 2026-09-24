#!/usr/bin/env sh
# shellcheck disable=SC2312

set -eu

nix run --option eval-cache false --no-write-lock-file --inputs-from path:. nixpkgs#flake-checker -- \
    --check-outdated --check-owner --check-supported --fail-mode --no-telemetry \
    --nixpkgs-keys nixpkgs,nixpkgs-unstable

# every machine and standalone home must evaluate on every CI platform
for attr in \
    nixosConfigurations.oulu.config.system.build.toplevel \
    nixosConfigurations.munich.config.system.build.toplevel \
    nixosConfigurations.solna.config.system.build.toplevel \
    nixosConfigurations.tampa.config.system.build.toplevel \
    nixosConfigurations.zadar.config.system.build.toplevel \
    darwinConfigurations.beirut.config.system.build.toplevel \
    darwinConfigurations.incheon.config.system.build.toplevel \
    'homeConfigurations."annt@wsl".activationPackage'; do
    printf 'eval %s\n' "${attr}"
    nix eval --option eval-cache false --no-write-lock-file --raw \
        "path:.#${attr}.drvPath" >/dev/null
done

nix fmt --option eval-cache false --no-write-lock-file -- --check

if test "$(uname -s)" = Linux; then
    nix flake check --option eval-cache false --no-write-lock-file path:. \
        --all-systems --no-build
fi

nix flake check --option eval-cache false --no-write-lock-file path:. \
    --print-build-logs
