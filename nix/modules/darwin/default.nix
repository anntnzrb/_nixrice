{ lib
, config
, pkgs
, namespace
, ...
}:
let
  cfg = config.${namespace}.darwin;
in
{
  options.${namespace}.darwin = with lib.liberion; with lib.types; {
    user = {
      name = mkOpt' str "annt";
    };
  };

  config = {
    nix.settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "@admin" ];
    };
    services.nix-daemon.enable = true;

    users.users.${cfg.user.name} = {
      inherit (cfg.user) name;
    };

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
