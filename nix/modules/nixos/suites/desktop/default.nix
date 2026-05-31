{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable {
    ${namespace} = {
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
