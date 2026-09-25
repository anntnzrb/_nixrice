{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptEnabled';

  cfg = config.liberion.darwin;
in
{
  options.liberion.darwin = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };

    system = {
      primaryUser = config.liberion.user.name;
      # booting beep/sound
      startup.chime = false;

      defaults = {
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
        # disable ads
        CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising =
          false;

        menuExtraClock = {
          IsAnalog = false;
          Show24Hour = true;
          ShowAMPM = false;
          ShowDate = 1; # always
          ShowSeconds = false;
        };
      };
    };

    system.stateVersion = 5;
  };
}
