{ config, lib, ... }:
let
  cfg = config.liberion.cli.tldr;
in
{
  options.liberion.cli.tldr = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.tealdeer = {
      enable = true;

      settings = {
        directories = {
          cache_dir = "${config.xdg.cacheHome}/tealdeer/cache/";
          custom_pages_dir = "${config.xdg.configHome}/tealdeer/custom/";
        };

        updates = {
          auto_update = true;
          auto_update_interval_hours = 168;
        };
      };
    };
  };
}
