{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.network.vpn.mullvad;
in
{
  options.liberion.network.vpn.mullvad = {
    enable = lib.mkEnableOption "mullvad";
  };

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
      enableExcludeWrapper = false;
    };
  };
}
