{ lib, ... }: {
  documentation.enable = false;
  programs.info.enable = false;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system = {
    primaryUser = lib.liberion.identity.user;
    stateVersion = 5;
    startup.chime = false;

    defaults = {
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising =
        false;

      menuExtraClock = {
        IsAnalog = false;
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 1;
        ShowSeconds = false;
      };
    };
  };
}
