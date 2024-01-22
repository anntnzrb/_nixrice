{ lib
, ...
}:

with lib.liberion; let
  autoStart = [
    "nm-applet"
    "pasystray"
    "redshift-gtk"
    "\${TERMINAL} -e btop"
  ];
in
{
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;

      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nvim";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";
      };

      bash = on;
    };

    cli = {
      btop = on;
      direnv = on;
      fzf = on;
      git = on;
      neofetch = on;
      simple-mtpfs = on;
      starship = on;
      yt-dlp = on;
    };

    editors = {
      emacs = {
        enable = true;
        pgtk = false;
      };

      neovim = on;
    };

    desktop = {
      sxhkd = {
        enable = true;
        timeout = 3;
        cancelKey = "Escape";
      };

      launchers.bemenu = on;

      window-managers.xorg.awesomewm = {
        enable = true;
        inherit autoStart;
        autorandr.enable = true;
      };

      browsers.firefox = on;
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      mpv = on;
      redshift = on;
      terminal-emulators.alacritty = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };
}
