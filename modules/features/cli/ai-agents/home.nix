{
  config,
  lib,
  pkgs,
  ...
}:
let
  repository = "https://github.com/anntnzrb/agents.git";
  destination = "${config.home.homeDirectory}/src/agents";
  updater = pkgs.writeShellApplication {
    name = "update-ai-agents";
    runtimeInputs = with pkgs; [
      coreutils
      git
      openssh
    ];
    text = builtins.readFile ./update.sh;
  };
  arguments = [
    (lib.getExe updater)
    repository
    destination
  ];
in
{
  systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    services.ai-agents = {
      Unit.Description = "Prepare and fast-forward the agents source checkout";
      Service = {
        Type = "oneshot";
        ExecStart = lib.escapeShellArgs arguments;
        TimeoutStartSec = 120;
        Nice = 19;
      };
    };
    timers.ai-agents = {
      Unit.Description = "Update the agents source checkout every five minutes";
      Timer = {
        OnStartupSec = "1min";
        OnUnitInactiveSec = "5min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  launchd.agents.ai-agents = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = arguments;
      RunAtLoad = true;
      StartInterval = 300;
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 19;
    };
  };
}
