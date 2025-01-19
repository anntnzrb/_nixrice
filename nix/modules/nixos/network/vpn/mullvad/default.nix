{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.network.vpn.mullvad;
in
{
  options.${namespace}.network.vpn.mullvad = with lib.${namespace}; {
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
