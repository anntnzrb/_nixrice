{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) ints str;

  cfg = config.liberion.desktop.whatsapp;
  dir = lib.types.pathWith {
    absolute = true;
    inStore = false;
  };

  homeDir = config.home.homeDirectory;

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
      description = "Quit WhatsApp after it has been idle";
      command = [
        (lib.getExe idleGuard)
        cfg.bundleId
        cfg.stateDir
        (toString (cfg.timeoutMinutes * 60))
        (toString (cfg.sleepBlockMinutes * 60))
        (toString cfg.killGraceSeconds)
      ];
      schedule = cfg.pollSeconds;
      startup = 0;
    })
  ];

  options.liberion.desktop.whatsapp = {
    bundleId = mkOpt' str "net.whatsapp.WhatsApp";
    timeoutMinutes = mkOpt' ints.positive 60;
    sleepBlockMinutes = mkOpt' ints.positive 10;
    pollSeconds = mkOpt' ints.positive 60;
    killGraceSeconds = mkOpt' ints.positive 10;
    stateDir = mkOpt' dir "${homeDir}/Library/Application Support/rice/whatsapp-idle-guard";
  };

  config = {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "liberion.desktop.whatsapp is only supported on Darwin.";
      }
    ];

    home.activation.whatsappIdleGuardDirs =
      lib.hm.dag.entryAfter [ "writeBoundary" ]
        ''
          run mkdir -p ${lib.escapeShellArg cfg.stateDir}
        '';
  };
}
