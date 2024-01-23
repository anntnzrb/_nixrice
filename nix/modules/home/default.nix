{ config
, lib
, ...
}:
let
  cfg = config.liberion.home;
in
{
  options.liberion.home = with lib.liberion; with lib.types; {
    packages = mkOpt' (listOf package) [ ];
  };

  config = {
    home = {
      stateVersion = "22.05";
      inherit (cfg) packages;
    };

    systemd.user.startServices = "sd-switch";
    programs.home-manager.enable = true;
  };
}
