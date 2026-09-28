#!/usr/bin/env sh

set -eu

flake="path:$(cd "${1:-.}" && pwd -P)"

if test "$#" -gt 0; then
    shift
fi

if test "$#" -eq 0; then
    set -- nixos darwin home
fi

kinds=""
for k in "$@"; do
    kinds="${kinds} \"${k}\""
done

nix eval --option eval-cache false --no-write-lock-file --raw \
    "${flake}#." --apply "f:
      let
        kinds = [${kinds} ];
        need = k: builtins.elem k kinds;
        nixos = if need \"nixos\" then builtins.concatStringsSep \"\" (builtins.attrValues (builtins.mapAttrs (n: c: \"nixos.\${n} \${c.config.system.build.toplevel.drvPath}\n\") (f.nixosConfigurations or {}))) else \"\";
        darwin = if need \"darwin\" then builtins.concatStringsSep \"\" (builtins.attrValues (builtins.mapAttrs (n: c: \"darwin.\${n} \${c.config.system.build.toplevel.drvPath}\n\") (f.darwinConfigurations or {}))) else \"\";
        home = if need \"home\" then builtins.concatStringsSep \"\" (builtins.attrValues (builtins.mapAttrs (n: c: \"home.\${n} \${c.activationPackage.drvPath}\n\") (f.homeConfigurations or {}))) else \"\";
      in
        nixos + darwin + home"
