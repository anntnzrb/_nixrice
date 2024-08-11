{ config
, inputs
, lib
, pkgs
, system
, namespace
, ...
}:
let
  cfg = config.${namespace}.desktop.browsers.firefox;
  addons = inputs.firefox-addons.packages.${system};
in
{
  options.${namespace}.desktop.browsers.firefox = with lib.${namespace}; {
    enable = mkOptBool';

    package = {
      install = mkOptEnabled';
    };
  };
  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = if cfg.package.install then pkgs.firefox else null;

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
                urls = [
                  {
                    template = "https://wiki.archlinux.org/index.php";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://wiki.archlinux.org/favicon.ico";
                updateInterval = weekInMs;
              };

              "GitHub" = {
                definedAliases = [ "@gh" ];
                urls = [
                  {
                    template = "https://github.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                      {
                        name = "type";
                        value = "code";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
                updateInterval = weekInMs;
              };

              "Nix Packages" = {
                definedAliases = [ "@nixp" ];
                urls = [
                  {
                    template = "https://search.nixos.org/packages?channel=unstable";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = weekInMs;
              };

              "GitHub: nixpkgs" = {
                definedAliases = [ "@gnixp" ];
                urls = [
                  {
                    template = "https://github.com/search";

                    params = [
                      {
                        name = "q";
                        value = "repo:NixOS/nixpkgs {searchTerms}";
                      }
                      {
                        name = "type";
                        value = "code";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = weekInMs;
              };

              "GitHub: Home-Manager" = {
                definedAliases = [ "@gnixhm" ];
                urls = [
                  {
                    template = "https://github.com/search";

                    params = [
                      {
                        name = "q";
                        value = "repo:nix-community/home-manager {searchTerms}";
                      }
                      {
                        name = "type";
                        value = "code";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = weekInMs;
              };

              "NixOS Wiki" = {
                definedAliases = [ "@nixw" ];
                urls = [
                  {
                    template = "https://nixos.wiki/index.php";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = weekInMs;
              };
              "Hoogle" = {
                definedAliases = [ "@hoogle" ];
                urls = [
                  {
                    template = "https://hoogle.haskell.org";

                    params = [
                      {
                        name = "hoogle";
                        value = "%2Bbase {searchTerms}";
                      }
                    ];
                  }
                ];

                iconUpdateURL = "https://www.haskell.org/img/favicon.ico";
                updateInterval = weekInMs;
              };
            };
        };

        extensions = with addons; [
          bitwarden # pw manager
          ublock-origin # ad-blocker
          clearurls
        ];

        settings = {
          "browser.fullscreen.autohide" = true;
          "browser.sessionstore.interval" = 45; # save session every X seconds
          "browser.startup.homepage" = "about:blank";
          "browser.startup.page" = 3; # continue where left off
          "browser.urlbar.clickSelectsAll" = true;

          "identity.fxaccounts.toolbar.defaultVisible" = false;

          "extensions.checkCompatibility" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.available" = "off";
          "extensions.formautofill.creditCards.available" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.formautofill.heuristics.enabled" = false;
          "extensions.getAddons.showPane" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.pocket.enabled" = false;
          "extensions.pocket.site" = "";

          "services.sync.engine.addons" = false;
          "services.sync.engine.creditcards" = false;
          "services.sync.engine.passwords" = false;

          "browser.ping-centre.telemetry" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.updatePing.enabled" = false;

          # misc
          "general.smoothScroll" = true;
          "network.prefetch-next" = false;
          "layout.spellcheckDefault" = 2;
        };
      };
    };
  };
}
