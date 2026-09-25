#!/usr/bin/env sh
# Prints "<class>.<name> <drvPath>" for every machine and standalone home of
# the flake at $1 (default: .). Two identical runs prove a refactor is pure.

set -eu

flake="path:$(cd "${1:-.}" && pwd)"

drvs() {
    nix eval --option eval-cache false --no-write-lock-file --raw \
        "${flake}#$1" --apply "cs: builtins.concatStringsSep \"\" (builtins.attrValues (builtins.mapAttrs (n: c: \"$2.\${n} \${c.$3.drvPath}\n\") cs))"
}

drvs nixosConfigurations nixos config.system.build.toplevel
drvs darwinConfigurations darwin config.system.build.toplevel
drvs homeConfigurations home activationPackage
