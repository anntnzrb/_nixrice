{ self, lib, ... }: {
  clan.core.enableRecommendedDefaults = lib.mkDefault false;

  documentation.enable = false;
  programs.info.enable = false;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system = {
    primaryUser = lib.liberion.identity.user;
    configurationRevision = self.rev or self.dirtyRev or null;
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
