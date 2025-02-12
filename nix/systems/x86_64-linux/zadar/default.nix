{
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [
    ./hardware
  ];

  ${namespace} = {
    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    hardware = {
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";

  services = {
    logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };
  };
}
