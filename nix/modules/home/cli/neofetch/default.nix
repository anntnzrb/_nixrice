{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.cli.neofetch;
in
{
  options.${namespace}.cli.neofetch = {
    enable = mkOptBool';
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
