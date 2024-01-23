{ lib
, ...
}:

with lib.liberion; let
  autoStart = [
    "nm-applet"
    "pasystray"
    "gammastep-indicator"
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
      launchers.bemenu = on;

      window-managers.wayland.sway = {
        enable = true;

        inherit autoStart;

        output = {
          HDMI-A-1 = {
            mode = "1366x768@60.000Hz";
            pos = "0,0";
            scale = "1.000";
          };
        };
      };

      browsers.firefox = on;
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      mpv = on;
      gammastep = on;
      terminal-emulators.alacritty = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };
}
