{ lib
, namespace
, ...
}:

with lib.${namespace}; let
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
        BROWSER = "chromium";
        EDITOR = "nvim";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";
      };

      bash = {
        enable = true;
        prompt.starship = on;
        zellij = on;
      };
    };

    cli = {
      git = {
        enable = true;
        lazygit = on;
      };

      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      simple-mtpfs = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
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
            compositor.picom.enable = true;
            inherit autoStart;
          };
        };
      };

      browsers = {
        chromium = on;
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
