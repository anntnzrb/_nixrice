#!/usr/bin/env sh

set -eu

root=$(git rev-parse --show-toplevel)
cd "${root}"

want=$(nix eval --impure --json --expr "
  let
    flake = builtins.getFlake \"path:${root}\";
    liberion = import ${root}/lib { inherit (flake.inputs.nixpkgs) lib; root = ${root}; };
  in
  {
    inherit (liberion.identity) user;
    keys = liberion.adminAgeKeys flake.clan.inventory.machines;
  }")

user=$(printf '%s' "${want}" | jq -r .user)
need=$(printf '%s' "${want}" | jq -r '.keys[]' | sort)
have=$(jq -r '.[].publickey' "sops/users/${user}/key.json" | sort)

add=$(printf '%s\n' "${need}" | grep -vxF -e "${have}" || true)
remove=$(printf '%s\n' "${have}" | grep -vxF -e "${need}" || true)

export CLAN_NO_COMMIT=1
for key in ${add}; do
    clan secrets users add-key "${user}" --age-key "${key}"
done
for key in ${remove}; do
    clan secrets users remove-key "${user}" --age-key "${key}"
done
clan vars fix
