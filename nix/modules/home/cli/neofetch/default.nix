{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.cli.neofetch;
in
{
  options.liberion.cli.neofetch = {
    enable = lib.mkEnableOption "neofetch";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.neofetch ];

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
