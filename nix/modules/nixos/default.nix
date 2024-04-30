{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.liberion.nixos;
in
{
  options.liberion.nixos = with lib.liberion; with lib.types; {
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
    variables = mkOpt' (attrsOf (oneOf [ (listOf str) str path ])) { };
  };

  config = {
    system.stateVersion = "22.05";

    nix = {
      settings = {
        trusted-users = [ "root" "@wheel" ];
        experimental-features = [ "nix-command" "flakes" ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        randomizedDelaySec = "45min";
      };
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    time = {
      inherit (cfg.time) timeZone hardwareClockInLocalTime;
    };

    environment = {
      systemPackages = with pkgs; [
        # liberion packages
        liberion.liberion

        # tools
        git

        # archiving
        atool
        p7zip
        rar
        unzip
        zip

        # misc
        nh
        kmon
        cachix
      ] ++ cfg.systemPackages;

      inherit (cfg) variables;
    };

    users.users.${cfg.user.name} = {
      inherit (cfg.user) name initialPassword isNormalUser extraGroups packages;
      openssh.authorizedKeys.keys = cfg.user.authorizedKeys;
    };
  };
}
