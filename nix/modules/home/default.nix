{ config
, lib
, ...
}:
let
  cfg = config.liberion.home;
in
{
  options.liberion.home = with lib; {
    packages = mkOption {
      type = with types; listOf package;
      default = [ ];
    };
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
