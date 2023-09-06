{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.cli.neofetch;
in {
  options.liberion.cli.neofetch = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.neofetch];

    xdg.configFile = {
      "neofetch" = {
        enable = true;
        source = ./config/neofetch;
        target = "neofetch";
        recursive = true;
      };
    };
  };
}
