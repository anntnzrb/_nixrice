{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.suites.desktop;
in
{
  options.liberion.suites.desktop.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable {
    liberion = {
      user = on;

      hardware = {
        audio.pipewire = on;
        keyboard.keyd = on;
      };

      network = {
        networkmanager = on;
        ssh = on;
        syncthing = on;
        vpn.mullvad = on;
      };

      common = {
        xorg = on;
        desktop = on;
      };
    };
  };
}
