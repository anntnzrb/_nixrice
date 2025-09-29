{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.cli.neofetch;
in
{
  options.${namespace}.cli.neofetch = {
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
