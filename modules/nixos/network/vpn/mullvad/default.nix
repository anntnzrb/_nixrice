{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.network.vpn.mullvad;
in
{
  options.${namespace}.network.vpn.mullvad = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      inherit (cfg) enable;
      package = pkgs.mullvad-vpn;
      enableExcludeWrapper = false;
    };
  };
}
