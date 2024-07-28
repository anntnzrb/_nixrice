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

      substituters = [
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
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
