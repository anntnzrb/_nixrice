{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.liberion.nixos;
in
{
  options.liberion.nixos =
    with lib.liberion;
    with lib.types;
    {
      time = {
        timeZone = mkOpt' str "America/New_York";
        hardwareClockInLocalTime = mkOptBool';
      };

      user = {
        name = mkOpt' str "annt";
        initialPassword = mkOpt' (nullOr str) "pass";
        isNormalUser = mkOptBool';
        extraGroups = mkOpt' (listOf str) [ ];
        packages = mkOpt' (listOf package) [ ];
        shell = mkOpt' str "bash";

        authorizedKeys = mkOpt' (listOf singleLineStr) [ ];
      };

      systemPackages = mkOpt' (listOf package) [ ];
      variables = mkOpt' (attrsOf (oneOf [
        (listOf str)
        str
        path
      ])) { };
    };

  config = {
    system.stateVersion = "22.05";

    nix = {
      settings = {
        trusted-users = [
          "root"
          "@wheel"
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://nix-community.cachix.org"
          "https://devenv.cachix.org"
          "https://anntnzrb.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "anntnzrb.cachix.org-1:hG29RyjX45a9q1nZqdvOJUQ6nRDG/Jj4yt2d1dpWCgE="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        randomizedDelaySec = "45min";
      };
    };

    i18n = rec {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = defaultLocale;
        LC_IDENTIFICATION = defaultLocale;
        LC_MEASUREMENT = defaultLocale;
        LC_MONETARY = defaultLocale;
        LC_NAME = defaultLocale;
        LC_NUMERIC = defaultLocale;
        LC_PAPER = defaultLocale;
        LC_TELEPHONE = defaultLocale;
        LC_TIME = defaultLocale;
      };
    };

    time = {
      inherit (cfg.time) timeZone hardwareClockInLocalTime;
    };

    documentation.man = {
      enable = true;
      generateCaches = true;
      man-db.enable = true;
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          # tools
          git
          man-pages-posix

          # archiving
          atool
          p7zip
          rar
          unzip
          zip

          # misc
          kmon
          cachix
        ]
        ++ cfg.systemPackages;

      inherit (cfg) variables;
    };

    users.users.${cfg.user.name} = {
      inherit (cfg.user)
        name
        initialPassword
        isNormalUser
        extraGroups
        packages
        ;
      openssh.authorizedKeys.keys = cfg.user.authorizedKeys;
    };
  };
}
