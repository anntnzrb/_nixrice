{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.neofetch;
in
{
  options.${namespace}.cli.neofetch = with lib.${namespace}; {
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
