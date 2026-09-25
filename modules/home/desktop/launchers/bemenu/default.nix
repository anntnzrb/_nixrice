import ../../../../toggle.nix "desktop.launchers.bemenu" (
  { pkgs, ... }: {
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
  }
)
