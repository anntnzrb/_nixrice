#!/usr/bin/env sh

set -eu

flake="path:$(cd "${1:-.}" && pwd)"

drvs() {
    nix eval --option eval-cache false --no-write-lock-file --raw \
        "${flake}#$1" --apply "cs: builtins.concatStringsSep \"\" (builtins.attrValues (builtins.mapAttrs (n: c: \"$2.\${n} \${c.$3.drvPath}\n\") cs))"
}

drvs nixosConfigurations nixos config.system.build.toplevel
drvs darwinConfigurations darwin config.system.build.toplevel
drvs homeConfigurations home activationPackage
