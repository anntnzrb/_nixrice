{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.zathura;
in
{
  options.liberion.desktop.zathura = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zathura = {
      inherit (cfg) enable;

      options = {
        sandbox = "none";
        selection-clipboard = "clipboard";
      };

      mappings = {
        "J" = "zoom out";
        "K" = "zoom in";

        "D" = "toggle_page_mode";
        "d" = "scroll half-down";
        "u" = "scroll half-up";

        "i" = "recolor";
        "r" = "reload";
        "p" = "print";
        "R" = "rotate";
      };
    };
  };
}
