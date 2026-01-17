{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    on
    off
    ;

  autoStart = {
    defaults = [
      "nm-applet"
      "pasystray"
      "\${TERMINAL} -e btop"
    ];

    xrandr = [
      "xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 0x0 --rate 75.000 --output HDMI-1-2 --mode 1920x1080 --pos 1920x0 --rate 60.000"
    ];
  };
in
{
  liberion = {
    suites.core = on;
    suites.cli = on;

    home = {
      keyboard = {
        layout = "us";
        variant = "altgr-intl";
        autoRepeatDelay = 220;
        autoRepeatInterval = 50;
      };
    };

    shells = {
      sessionVariables = {
        BROWSER = "firefox";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";
      };

      bash = on;
    };

    cli = {
      neofetch = off;
    };

    editors = {
      emacs = on;
      vscode = on;
    };

    desktop = {
      sxhkd = on // {
        timeout = 3;
        cancelKey = "Escape";
      };

      launchers = {
        wofi = off;
        bemenu = on;
      };

      window-managers = {
        xorg = {
          awesomewm = on // {
            compositor.picom = on // {
              vSync = true;
            };
            autoStart = autoStart.defaults ++ autoStart.xrandr;
          };

          herbstluftwm = off // {
            compositor.picom = on;
          };

          xmonad = off // {
            compositor.picom = on;
            autoStart = autoStart.defaults ++ autoStart.xrandr;
          };
        };

        wayland = {
          sway = off // {
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

          hyprland = off // {
            waybar = on;
            autoStartApps = autoStart.defaults;
            monitor = [
              "HDMI-A-2, 1366x768, 1920x0, 1"
              "HDMI-A-3, 1920x1080, 0x0, 1"
            ];
          };
        };
      };

      browsers = {
        firefox = on;
        chromium = off;
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

      ui.themes = on;
    };
  };
}
