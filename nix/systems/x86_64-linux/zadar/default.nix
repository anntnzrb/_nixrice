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

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
