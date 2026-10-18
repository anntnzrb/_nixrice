{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) ints;

  cfg = config.liberion.desktop.whatsapp;
  app = lib.types.pathWith {
    absolute = true;
    inStore = false;
  };

  idleGuard = pkgs.writeShellApplication {
    name = "whatsapp-idle-guard";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile ./whatsapp-idle-guard.sh;
  };
in
{
  imports = [
    (lib.liberion.userJob {
      name = "whatsapp-idle-guard";
      description = "Quit WhatsApp while it blocks sleep";
      command = [
        (lib.getExe idleGuard)
        cfg.appPath
        (toString (cfg.sleepBlockMinutes * 60))
        (toString cfg.killGraceSeconds)
      ];
      schedule = cfg.pollSeconds;
      startup = 0;
    })
  ];

  options.liberion.desktop.whatsapp = {
    appPath = mkOpt' app "/Applications/WhatsApp.app";
    sleepBlockMinutes = mkOpt' ints.positive 10;
    pollSeconds = mkOpt' ints.positive 60;
    killGraceSeconds = mkOpt' ints.positive 10;
  };

  config.assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.isDarwin;
      message = "liberion.desktop.whatsapp is only supported on Darwin.";
    }
  ];
}
