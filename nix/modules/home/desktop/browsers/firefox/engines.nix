let
  updateInterval = 24 * 60 * 60 * 7 * 1000; # 1 week in ms
in
{
  config.programs.firefox.profiles.default.search.engines = {
    # ---------------------------------------------------------------------------
    # nix
    # ---------------------------------------------------------------------------
    nixpkgs = {
      name = "Nix Packages";
      definedAliases = [ "@nixp" ];
      icon = "https://nixos.wiki/favicon.png";
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

    gh-nixpkgs = {
      name = "GitHub: nixpkgs";
      definedAliases = [ "@gnixp" ];
      icon = "https://nixos.wiki/favicon.png";
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

    nixos-wiki = {
      name = "NixOS Wiki";
      definedAliases = [ "@nixw" ];
      icon = "https://nixos.wiki/favicon.png";
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

    noogle = {
      name = "Noogle";
      definedAliases = [ "@noogle" ];
      icon = "https://noogle.dev/favicon.png";
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

    gh-home-manager = {
      name = "GitHub: Home-Manager";
      definedAliases = [ "@gnixhm" ];
      icon = "https://nixos.wiki/favicon.png";
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

    arch-wiki = {
      name = "Arch Wiki";
      definedAliases = [ "@aw" ];
      icon = "https://wiki.archlinux.org/favicon.ico";
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

    gh = {
      name = "GitHub";
      definedAliases = [ "@gh" ];
      icon = "https://github.githubassets.com/favicons/favicon.png";
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

    hoogle = {
      name = "Hoogle";
      definedAliases = [ "@hoogle" ];
      icon = "https://www.haskell.org/img/favicon.ico";
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
