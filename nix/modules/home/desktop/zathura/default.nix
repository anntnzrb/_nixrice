{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.zathura;
in
{
  options.${namespace}.desktop.zathura = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zathura = {
      enable = true;

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
