{ pkgs
, inputs
, hostInfo
, ...
}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.default = {
      id = 0; # default
      name = "default";

      search = {
        default = "DuckDuckGo";
        force = true;

        engines =
          let
            weekInMs = 24 * 60 * 60 * 7 * 1000;
          in
          {
            "Arch Wiki" = {
              definedAliases = [ "@aw" ];
              urls = [{
                template = "https://wiki.archlinux.org/index.php";
                params = [{ name = "search"; value = "{searchTerms}"; }];
              }];

              iconUpdateURL = "https://wiki.archlinux.org/favicon.ico";
              updateInterval = weekInMs;
            };

            "GitHub" = {
              definedAliases = [ "@gh" ];
              urls = [{
                template = "https://github.com/search";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                  { name = "type"; value = "code"; }
                ];
              }];

              iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
              updateInterval = weekInMs;
            };

            "Nix Packages" = {
              definedAliases = [ "@nixp" ];
              urls = [{
                template = "https://search.nixos.org/packages?channel=unstable";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];

              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = weekInMs;
            };

            "NixOS Wiki" = {
              definedAliases = [ "@nixw" ];
              urls = [{
                template = "https://nixos.wiki/index.php";
                params = [{ name = "search"; value = "{searchTerms}"; }];
              }];

              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = weekInMs;
            };
          };

      };

      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
        ublock-origin
        bitwarden
        tridactyl
      ];

      settings = {
        "browser.startup.page" = 3;
      };
    };
  };
}
