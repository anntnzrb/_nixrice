{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.launchers.bemenu;
in
{
  options.liberion.desktop.launchers.bemenu = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.bemenu ];

      sessionVariables = {
        BEMENU_OPTS = "--ignorecase --center --wrap --list=10 --scrollbar='autohide' --border=3 --border-radius=12 --width-factor=0.5 --line-height=20 --prompt=Invoke:";
      };
    };
  };
}
