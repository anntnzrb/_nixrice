{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.terminal.alacritty;
in {
  options.liberion.desktop.terminal.alacritty = {
    enable = mkOptBool' true;
  };

  config = mkIf cfg.enable {
    programs.alacritty.enable = true;

    xdg.configFile = {
      "alacritty" = {
        enable = true;
        source = ./config/alacritty;
        target = "alacritty";
        recursive = true;
      };
    };
  };
}
