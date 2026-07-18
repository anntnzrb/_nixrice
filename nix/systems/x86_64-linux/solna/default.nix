{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ./hardware ];

  ${namespace} = {
    suites.desktop = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;
  };
}
