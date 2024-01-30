{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.browsers.qutebrowser;
in
{
  options.liberion.desktop.browsers.qutebrowser = with lib.liberion; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    programs.qutebrowser = {
      enable = true;

      loadAutoconfig = false;
      enableDefaultBindings = true;

      searchEngines = {
        DEFAULT = "https://search.brave.com/search?q={}";

        # nix
        nixp = "https://search.nixos.org/packages?channel=unstable&type=packages&query={}";
        nixpgh = "https://github.com/search?q=repo:NixOS/nixpkgs%20{}&type=code";
        nixw = "https://nixos.wiki/index.php?search={}";
        nixhmgh = "https://github.com/search?q=repo:nix-community/home-manager%20{}&type=code";
        nixmy = "https://mynixos.com/search?q={}";

        # misc
        aw = "https://wiki.archlinux.org/?search={}";
        hoogle = "https://hoogle.haskell.org/?hoogle=%2Bbase%20{}";
        gmaps = "https://www.google.com/maps/place/{}";
        ghub = "https://github.com/search?q={}&type=code";
        yt = "https://www.youtube.com/results?search_query={}";
        libgen = "https://libgen.is/search.php?&req={}&sort=year&sortmode=DESC";
      };

      settings = {
        backend = "webengine";
        changelog_after_upgrade = "minor";
        confirm_quit = [ "never" ];
        # spellcheck.languages = [ "en-US" "en-GB" "es-ES" ];
        qt.chromium.low_end_device_mode = "never";

        window = {
          hide_decoration = true;
          transparent = false;
        };

        statusbar = {
          show = "always";
          position = "top";
          widgets = [ "progress" "keypress" "search_match" "scroll" "url" ];
        };

        tabs = {
          show = "always";
          tabs_are_windows = false;
          background = false;
          mousewheel_switching = false;
          close_mouse_button = "none";
          last_close = "close";

          position = "left";
          width = "2%";

          title.format = "";
        };

        url = {
          auto_search = "dns";
          default_page = "https://search.atlas.engineer";
        };

        fonts = {
          default_size = "11pt";
        };

        hints = {
          mode = "letter";
          chars = "qawsedrftg";
          min_chars = 1;
          uppercase = true;
          find_implementation = "python";
        };

        input = {
          mouse.back_forward_buttons = false; # forces me not to use it

          insert_mode = {
            auto_enter = true;
            auto_leave = true;
            auto_load = false;
            leave_on_load = true;
          };
        };

        scrolling = {
          bar = "never";
          smooth = true;
        };

        search = {
          ignore_case = "always";
        };

        auto_save = {
          interval = 30 * 1000;
          session = true;
        };

        completion = {
          delay = 250;
          height = "25%";
          min_chars = 2;
        };

        downloads = {
          position = "top";

          location = {
            directory = "${config.xdg.userDirs.download}";
            prompt = false;
            remember = false;
            suggestion = "both";
          };
        };

        content = {
          autoplay = false;
          desktop_capture = "ask";
          geolocation = "ask";
          pdfjs = true;
          mouse_lock = "ask";

          blocking = {
            enabled = true;
            method = "both";
          };

          javascript = {
            enabled = true;
            can_close_tabs = false;
            can_open_tabs_automatically = false;
            clipboard = "none";
          };

          media = {
            audio_capture = "ask";
            audio_video_capture = "ask";
            video_capture = "ask";
          };
        };
      };
    };
  };
}
