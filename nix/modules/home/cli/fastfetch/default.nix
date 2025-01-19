{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.fastfetch;
in
{
  options.${namespace}.cli.fastfetch = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.fastfetch ];

    xdg.configFile =
      let
        cfg = "config.jsonc";
      in
      {
        fastfetch = {
          enable = true;
          source = ./${cfg};
          target = "${config.xdg.configHome}/fastfetch/${cfg}";
          recursive = true;
        };
      };
  };
}
