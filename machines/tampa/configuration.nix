{ lib, ... }:

let
  inherit (lib.liberion.module) on;
in
{
  nixpkgs.hostPlatform = "x86_64-linux";

  liberion = {
    user = on;

    wsl = on;

    network.ssh = on;
  };
}
