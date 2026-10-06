{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  linux = pkgs.stdenv.hostPlatform.isLinux;
  log = "${home}/.cache/amp/logs/runner-agents.log";
in
{
  imports = [
    inputs.self.homeModules.ai-agents
    # Serves ~/repos checkouts and the agents checkout from a neutral cwd. Only
    # Linux gets a private headless desktop; on macOS --desktop would share
    # the Mac's real screen.
    (lib.liberion.userService {
      name = "amp-runner";
      description = "Amp runner";
      command = [
        "${home}/.local/bin/amp"
        "--no-tui"
        "--runner-id"
        osConfig.networking.hostName
        "--no-notifications"
        "--discover-dirs=${home}/repos"
        "--discover-depth"
        "3"
        "--dir"
        "${home}/src/agents"
      ]
      ++ lib.optional linux "--desktop"
      ++ [
        "--log-file"
        log
      ];
    })
    (lib.liberion.userJob {
      name = "amp-runner-update";
      description = "Restart the Amp runner onto its newest release when idle";
      schedule = "nightly";
      timeout = 900;
      command = lib.liberion.agentsSync config ++ [
        "job"
        "amp-runner-update"
        "--service"
        (if linux then "amp-runner.service" else "org.nix-community.home.amp-runner")
        "--log-file"
        log
      ];
    })
  ];
}
