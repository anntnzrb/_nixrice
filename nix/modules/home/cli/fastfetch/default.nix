{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.cli.fastfetch;
in
{
  options.liberion.cli.fastfetch = with lib.liberion; {
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
