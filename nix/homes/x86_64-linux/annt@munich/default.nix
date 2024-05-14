{ pkgs
, lib
, ...
}:

with lib.liberion; let
  autoStart = {
    defaults = [
      "nm-applet"
      "pasystray"
      "\${TERMINAL} -e btop"
    ];

    xrandr = [ "xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 0x0 --rate 75.000 --output HDMI-1-2 --mode 1920x1080 --pos 1920x0 --rate 60.000" ];
  };
in
{
  liberion = {
    home = {
      packages = with pkgs; [
        git # example
      ];

      keyboard = {
        layout = "us";
        variant = "altgr-intl";
        autoRepeatDelay = 220;
        autoRepeatInterval = 50;
      };
    };

    shells = {
      defaults = on;
      altCoreUtils = on;

      sessionVariables = {
        BROWSER = "chromium";
        EDITOR = "nvim";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";
      };

      bash = on;
    };

    cli = {
      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      git = on;
      neofetch = off;
      simple-mtpfs = on;
      starship = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      emacs = {
        enable = false;
        pgtk = false;
      };

      neovim = on;
      vscode = on;
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
        xorg = {
          awesomewm = {
            enable = true;
            compositor.picom = {
              enable = true;
              vSync = true;
            };
            autoStart = autoStart.defaults ++ autoStart.xrandr;
          };

          herbstluftwm = {
            enable = false;
            compositor.picom.enable = true;
          };

          xmonad = {
            enable = false;
            compositor.picom.enable = true;
            autoStart = autoStart.defaults ++ autoStart.xrandr;
          };
        };

        wayland = {
          sway = {
            enable = false;
            autoStart = autoStart.defaults;
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
            autoStartApps = autoStart.defaults;
            monitor = [ "HDMI-A-2, 1366x768, 1920x0, 1" "HDMI-A-3, 1920x1080, 0x0, 1" ];
          };
        };
      };

      browsers = {
        firefox = on;
        chromium = on;
        qutebrowser = on;
      };
      discord = on;
      feh = on;
      file-managers.pcmanfm = on;
      flameshot = on;
      gammastep = on;
      mpv = on;
      obs = on;
      terminal-emulators.alacritty = on;
      zathura = on;

      ui = {
        themes = on;
        fonts = on;
      };
    };
  };
}
