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
  wrapper = "${home}/.local/bin/amp";
  log = "${home}/.cache/amp/logs/runner-agents.log";
in
{
  # Amp refuses to start when a --discover-dirs directory is missing.
  home.activation.ampRunnerRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${home}/repos"}
  '';

  imports = [
    inputs.self.homeModules.ai-agents
    # Serves ~/repos checkouts and the agents checkout from a neutral cwd. Only
    # Linux gets a private headless desktop; on macOS --desktop would share
    # the Mac's real screen.
    (lib.liberion.userService {
      name = "amp-runner";
      description = "Amp runner";
      command = [
        wrapper
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
      command = [
        (lib.getExe pkgs.python3)
        "${./amp-runner-update.py}"
        "--wrapper"
        wrapper
        "--service"
        (if linux then "amp-runner.service" else "org.nix-community.home.amp-runner")
        "--log-file"
        log
      ];
    })
  ];
}
