{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.network.vpn.mullvad;
in
{
  options.liberion.network.vpn.mullvad = {
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
