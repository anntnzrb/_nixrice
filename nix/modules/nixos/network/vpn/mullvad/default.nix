{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.network.vpn.mullvad;
in
{
  options.${namespace}.network.vpn.mullvad = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
      enableExcludeWrapper = false;
    };
  };
}
