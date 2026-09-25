# Firefox search engines: attr = engine name, aliases, icon, url template and
# its query params as ordered [ name value ] pairs.
let
  engine = name: aliases: icon: template: params: {
    inherit name icon;
    definedAliases = aliases;
    updateInterval = 24 * 60 * 60 * 7 * 1000; # 1 week in ms
    urls = [
      {
        inherit template;
        params = map (p: {
          name = builtins.elemAt p 0;
          value = builtins.elemAt p 1;
        }) params;
      }
    ];
  };

  q = "{searchTerms}";
  nixIcon = "https://nixos.wiki/favicon.png";
  githubCode = query: [
    [
      "q"
      query
    ]
    [
      "type"
      "code"
    ]
  ];
in
{
  # default
  perplexity =
    engine "Perplexity" [ "@p" "@perplexity" ]
      "https://www.perplexity.ai/favicon.ico"
      "https://www.perplexity.ai/search"
      [
        [
          "q"
          q
        ]
      ];

  # nix
  nixpkgs =
    engine "Nix Packages" [ "@nixp" ] nixIcon
      "https://search.nixos.org/packages?channel=unstable"
      [
        [
          "type"
          "packages"
        ]
        [
          "query"
          q
        ]
      ];
  gh-nixpkgs = engine "GitHub: nixpkgs" [
    "@gnixp"
  ] nixIcon "https://github.com/search" (githubCode "repo:NixOS/nixpkgs ${q}");
  nixos-wiki =
    engine "NixOS Wiki" [ "@nixw" ] nixIcon "https://nixos.wiki/index.php"
      [
        [
          "search"
          q
        ]
      ];
  noogle =
    engine "Noogle" [ "@noogle" ] "https://noogle.dev/favicon.png"
      "https://noogle.dev/q"
      [
        [
          "term"
          q
        ]
      ];
  gh-home-manager =
    engine "GitHub: Home-Manager" [ "@gnixhm" ] nixIcon "https://github.com/search"
      (githubCode "repo:nix-community/home-manager ${q}");

  # misc
  arch-wiki =
    engine "Arch Wiki" [ "@aw" ] "https://wiki.archlinux.org/favicon.ico"
      "https://wiki.archlinux.org/index.php"
      [
        [
          "search"
          q
        ]
      ];
  gh =
    engine "GitHub" [ "@gh" ] "https://github.githubassets.com/favicons/favicon.png"
      "https://github.com/search"
      (githubCode q);
  hoogle =
    engine "Hoogle" [ "@hoogle" ] "https://www.haskell.org/img/favicon.ico"
      "https://hoogle.haskell.org"
      [
        [
          "hoogle"
          "%2Bbase ${q}"
        ]
      ];
}
