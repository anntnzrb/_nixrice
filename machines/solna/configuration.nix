{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ ./hardware ];

  nixpkgs.hostPlatform = "x86_64-linux";

  liberion = {
    suites.desktop = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;
  };
}
