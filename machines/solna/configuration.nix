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
  imports = [
    self.nixosModules.default
    ./hardware
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  ${namespace} = {
    suites.desktop = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;
  };
}
