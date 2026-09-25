{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.cli.neofetch;
in
{
  options.liberion.cli.neofetch = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.neofetch ];

    xdg.configFile = {
      "neofetch" = on // {
        source = ./config/neofetch;
        target = "neofetch";
        recursive = true;
      };
    };
  };
}
