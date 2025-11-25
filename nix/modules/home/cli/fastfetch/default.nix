{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.cli.fastfetch;
in
{
  options.${namespace}.cli.fastfetch = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.fastfetch ];

    xdg.configFile =
      let
        configFile = "config.jsonc";
      in
      {
        fastfetch = on // {
          source = ./${configFile};
          target = "fastfetch/${configFile}";
          recursive = true;
        };
      };
  };
}
