#!/usr/bin/env sh
# Builds every machine and standalone home this platform can build (Linux:
# NixOS systems and homes; macOS: nix-darwin systems), so a package that
# evaluates but fails to build shows up before a deploy.

set -eu

flake="path:$(pwd)"

# "<output>.<name>.<attr>" installables for every entry of a flake output
installables() {
    nix eval --raw "${flake}#$1" \
        --apply "cs: builtins.concatStringsSep \" \" (map (n: \"$1.\\\"\${n}\\\".$2\") (builtins.attrNames cs))"
}

platform="$(uname -s)"
case "${platform}" in
    Linux)
        systems="$(installables nixosConfigurations config.system.build.toplevel)"
        homes="$(installables homeConfigurations activationPackage)"
        targets="${systems} ${homes}"
        ;;
    Darwin)
        targets="$(installables darwinConfigurations system)"
        ;;
    *)
        echo "unsupported platform: ${platform}" >&2
        exit 1
        ;;
esac

set --
for target in ${targets}; do
    set -- "$@" "${flake}#${target}"
done

nix build --keep-going --no-link --print-build-logs "$@"
