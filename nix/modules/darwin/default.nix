{
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace};
in
{
  #imports = [ ./activation.nix ];

  config = {
    security.pam.services.sudo_local.touchIdAuth = true;

    system = {
      primaryUser = "annt";
      # booting beep/sound
      startup.chime = false;

      defaults = {
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
        # disable ads
        CustomUserPreferences."com.apple.AdLib".allowApplePersonalizedAdvertising =
          false;

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

    system.stateVersion = 5;
  };
}
