{ lib, self, ... }:

let
  inherit (lib.liberion.module) on;
in
{
  imports = [ self.nixosModules.default ];

  nixpkgs.hostPlatform = "x86_64-linux";

  liberion = {
    user = on;

    wsl = on;

    network.ssh = on;
  };
}
