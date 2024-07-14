{ config
, pkgs
, namespace
, ...
}:
let
  _cfg = config.${namespace}.darwin;
in
{
  config = {
    services.nix-daemon.enable = true;

    system = {
      # booting beep/sound
      startup.chime = false;

      defaults = {
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

        # TODO: get more related stuff for move
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
    ];
  };

}
