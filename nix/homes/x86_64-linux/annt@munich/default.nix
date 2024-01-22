{ pkgs
, lib
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
    home.packages = with pkgs; [
      git # example
    ];

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

      launchers = {
        wofi = off;
        bemenu = on;
      };

      window-managers = {
        wayland = {
          hyprland = {
            enable = false;
            waybar = on;
            autoStartApps = autoStart;
            monitor = [ "HDMI-A-2, 1366x768, 1920x0, 1" "HDMI-A-3, 1920x1080, 0x0, 1" ];
            keyboard = {
              layout = "us";
              variant = "altgr-intl";
            };
          };
        };

        xorg = {
          awesomewm = {
            enable = true;
            inherit autoStart;
            autorandr.enable = true;
          };
        };
      };

      browsers.firefox = on;
      discord = on;
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      mpv = on;
      obs = on;
      redshift = on;
      terminal-emulators.alacritty = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };
}
