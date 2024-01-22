{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.liberion.nixos;
in
{
  options.liberion.nixos = with lib; {
    time = {
      timeZone = mkOption {
        type = types.str;
        default = "America/New_York";
      };

      hardwareClockInLocalTime = mkOption {
        type = types.bool;
        default = false;
        description = "use local time over UTC?";
      };
    };

    user = {
      name = mkOption {
        type = types.str;
        default = "annt";
      };

      initialPassword = mkOption {
        type = with types; nullOr str;
        default = "pass";
      };

      isNormalUser = mkOption {
        type = types.bool;
        default = false;
      };

      extraGroups = mkOption {
        type = with types; listOf str;
        default = [ ];
      };

      packages = mkOption {
        type = with types; listOf package;
        default = [ ];
      };

      shell = mkOption {
        type = types.str;
        default = "bash";
      };

      authorizedKeys = mkOption {
        type = with types; listOf singleLineStr;
        default = [ ];
      };
    };

    systemPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
    };

    variables = mkOption {
      type = with types; attrsOf (oneOf [ (listOf str) str path ]);
      default = { };
    };
  };

  config = {
    system.stateVersion = "22.05";

    nix.settings.trusted-users = [ "root" "@wheel" ];

    time = {
      inherit (cfg.time) timeZone hardwareClockInLocalTime;
    };

    environment = {
      systemPackages = with pkgs; [
        liberion.liberion

        git

        # archiving
        atool
        p7zip
        rar
        unrar
        unzip
        zip

        # misc
        kmon
      ] ++ cfg.systemPackages;

      inherit (cfg) variables;
    };

    users.users.${cfg.user.name} = {
      inherit (cfg.user) name initialPassword isNormalUser extraGroups packages;
      openssh.authorizedKeys.keys = cfg.user.authorizedKeys;
    };
  };
}
