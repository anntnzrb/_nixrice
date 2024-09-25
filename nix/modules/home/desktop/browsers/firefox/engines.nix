let
  updateInterval = 24 * 60 * 60 * 7 * 1000; # 1 week in ms
in
{
  config.programs.firefox.profiles.default.search.engines = {
    # ---------------------------------------------------------------------------
    # nix
    # ---------------------------------------------------------------------------
    "Nix Packages" = {
      definedAliases = [ "@nixp" ];
      iconUpdateURL = "https://nixos.wiki/favicon.png";
      inherit updateInterval;
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
    };

    "GitHub: nixpkgs" = {
      definedAliases = [ "@gnixp" ];
      iconUpdateURL = "https://nixos.wiki/favicon.png";
      inherit updateInterval;
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
    };

    "NixOS Wiki" = {
      definedAliases = [ "@nixw" ];
      iconUpdateURL = "https://nixos.wiki/favicon.png";
      inherit updateInterval;
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
    };

    "Noogle" = {
      definedAliases = [ "@noogle" ];
      iconUpdateURL = "https://noogle.dev/favicon.png";
      inherit updateInterval;
      urls = [
        {
          template = "https://noogle.dev/q";
          params = [
            {
              name = "term";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };

    "GitHub: Home-Manager" = {
      definedAliases = [ "@gnixhm" ];
      iconUpdateURL = "https://nixos.wiki/favicon.png";
      inherit updateInterval;
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
    };

    # ---------------------------------------------------------------------------
    # misc
    # ---------------------------------------------------------------------------

    "Arch Wiki" = {
      definedAliases = [ "@aw" ];
      iconUpdateURL = "https://wiki.archlinux.org/favicon.ico";
      inherit updateInterval;
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
    };

    "GitHub" = {
      definedAliases = [ "@gh" ];
      iconUpdateURL = "https://github.githubassets.com/favicons/favicon.png";
      inherit updateInterval;
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
    };

    "Hoogle" = {
      definedAliases = [ "@hoogle" ];
      iconUpdateURL = "https://www.haskell.org/img/favicon.ico";
      inherit updateInterval;
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
    };
  };
}
