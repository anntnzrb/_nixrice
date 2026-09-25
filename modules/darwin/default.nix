# nix-darwin baseline for every liberion host.
{ config, ... }: {
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system = {
    primaryUser = config.liberion.user.name;
    stateVersion = 5;
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
}
