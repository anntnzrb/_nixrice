{
  lib,
  self,
  namespace,
  ...
}:

let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ self.nixosModules.default ];

  nixpkgs.hostPlatform = "x86_64-linux";

  ${namespace} = {
    user = on;

    wsl = on;

    network.ssh = on;
  };
}
