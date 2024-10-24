{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.darwin;
in
{
  imports = [ ./activation.nix ];

  options.${namespace}.darwin =
    with lib.liberion;
    with lib.types;
    {
      user = {
        name = mkOpt' types.str "annt";
        authorizedKeys = mkOpt' (types.listOf types.singleLineStr) [ ];
      };
    };

  config = {
    nix = {
      package = pkgs.nix;
      gc = {
        automatic = true;
        interval.Day = 7;
        options = "--delete-older-than 7d";
      };
    };

    nix.settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@admin"
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

    services.nix-daemon.enable = true;
    security.pam.enableSudoTouchIdAuth = true;

    users.users.${cfg.user.name} = {
      inherit (cfg.user) name;
      openssh.authorizedKeys.keys = cfg.user.authorizedKeys;
    };

    system = {
      # booting beep/sound
      startup.chime = false;

      defaults = {
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
        # disable ads
        CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising = false;

        menuExtraClock =
          let
            always = 1;
          in
          {
            IsAnalog = false;
            Show24Hour = true;
            ShowAMPM = false;
            ShowDate = always;
            ShowSeconds = false;
          };
      };
    };

    environment.systemPackages = with pkgs; [
      curl
      wget
      cachix
    ];

    system.stateVersion = 4;
  };
}
