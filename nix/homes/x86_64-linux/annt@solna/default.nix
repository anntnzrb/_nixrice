{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;

  autoStart = [
    "nm-applet"
    "pasystray"
    "\${TERMINAL} -e btop"
  ];
in
{
  liberion = {
    shells = {
      sessionVariables = {
        BROWSER = "chromium";
        EDITOR = "nvim";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";
      };
      prompt.starship = on;

      bash = on;
    };

    cli = {
      git = on // {
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
      sxhkd = on // {
        timeout = 3;
        cancelKey = "Escape";
      };

      launchers.bemenu = on;

      window-managers = {
        xorg = {
          awesomewm = on // {
            compositor.picom = on;
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
      gammastep = on;
      mpv = on;
      terminal-emulators.alacritty = on;
      zathura = on;

      ui.themes = on;
    };
  };

  services.cbatticon = on // {
    updateIntervalSeconds = 30;
    lowLevelPercent = 25;
    criticalLevelPercent = 10;
  };
}
