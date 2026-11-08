#!/usr/bin/env sh
# Usage: wsl-image.sh <machine> <output>
# Builds the NixOS-WSL tarball of <machine>; needs root for nixos-install.

set -eu

machine="$1"
out="$2"
limit=$((2 * 1024 * 1024 * 1024))

builder="$(nix build --no-link --print-out-paths --print-build-logs \
    "path:${PWD}#nixosConfigurations.${machine}.config.system.build.tarballBuilder")"
sudo "${builder}/bin/nixos-wsl-tarball-builder" "${out}"
uid="$(id -u)"
gid="$(id -g)"
sudo chown "${uid}:${gid}" "${out}"

size="$(stat -c %s "${out}")"
echo "${out}: ${size} bytes"
if test "${size}" -ge "${limit}"; then
    echo "${out} exceeds the 2 GiB GitHub release asset limit" >&2
    exit 1
fi
