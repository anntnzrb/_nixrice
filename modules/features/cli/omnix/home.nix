{ lib, pkgs, ... }: {
  home.shellAliases.om = "${lib.getExe pkgs.nix} --accept-flake-config run github:juspay/omnix --";
}
