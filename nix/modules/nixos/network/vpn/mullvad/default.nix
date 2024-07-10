{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.network.vpn.mullvad;
in
{
  options.liberion.network.vpn.mullvad = with lib.liberion; {
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
