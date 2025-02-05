{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.desktop.launchers.bemenu;
in
{
  options.${namespace}.desktop.launchers.bemenu = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.bemenu ];

      sessionVariables = {
        BEMENU_OPTS = "--ignorecase --center --wrap --list=10 --scrollbar='autohide' --border=3 --border-radius=12 --width-factor=0.5 --line-height=20 --prompt=Invoke:";
      };
    };

    services.sxhkd = {
      keybindings = {
        "super + d ; {d}" = "{bemenu-run}";
      };
    };
  };
}
