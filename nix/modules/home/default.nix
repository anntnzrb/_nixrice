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
      inherit (cfg) packages;
      stateVersion = "22.05";
    };

    systemd.user.startServices = "sd-switch";
    programs.home-manager.enable = true;
  };
}
