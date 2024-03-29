{ lib
, ...
}:

with lib.liberion; let
  autoStart = [
    "nm-applet"
    "pasystray"
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
      fastfetch = on;
      simple-mtpfs = on;
      starship = on;
      tldr = on;
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

      window-managers = {
        xorg = {
          awesomewm = {
            enable = true;
            inherit autoStart;
          };
        };
      };

      browsers = {
        firefox = on;
        qutebrowser = on;
      };
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      mpv = on;
      gammastep = on;
      terminal-emulators.alacritty = on;
      zathura = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };

  services.cbatticon = {
    enable = true;
    updateIntervalSeconds = 30;
    lowLevelPercent = 25;
    criticalLevelPercent = 10;
  };
}
