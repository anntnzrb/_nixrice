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
}
