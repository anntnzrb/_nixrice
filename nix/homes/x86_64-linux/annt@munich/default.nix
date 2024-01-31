{ pkgs
, lib
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
      neofetch = off;
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
        enable = false;
        timeout = 3;
        cancelKey = "Escape";
      };

      launchers = {
        wofi = off;
        bemenu = on;
      };

      window-managers = {
        xorg = {
          xmonad = {
            enable = true;
            autoStart = autoStart ++ [ "xrandr --output HDMI-3 --mode 1366x768 --pos 1920x0 --output HDMI-1-1 --primary --mode 1920x1080 --pos 0x0 --rate 60.00" ];
          };
        };

        wayland = {
          sway = {
            enable = false;

            inherit autoStart;

            output = {
              HDMI-A-3 = {
                mode = "1920x1080@60.000Hz";
                pos = "1920,0";
                scale = "1.500";
              };

              HDMI-A-1 = {
                mode = "1920x1080@60.000Hz";
                pos = "0,0";
                scale = "1.000";
              };
            };
          };

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
      };

      browsers = {
        firefox = on;
        qutebrowser = on;
      };
      discord = on;
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      mpv = on;
      obs = on;
      gammastep = on;
      terminal-emulators.alacritty = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };
}
