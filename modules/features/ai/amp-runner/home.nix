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
  wrapper = "${home}/.local/bin/amp";
  log = "${home}/.cache/amp/logs/runner-agents.log";
in
{
  options.liberion.ai.amp-runner.desktop =
    lib.liberion.module.mkOpt' lib.types.bool pkgs.stdenv.hostPlatform.isLinux;

  # Amp refuses to start when a --discover-dirs directory is missing.
  config.home.activation.ampRunnerRepos =
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      ''
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
      ++ lib.optional config.liberion.ai.amp-runner.desktop "--desktop"
      ++ [
        "--log-file"
        log
      ];
    })
    (lib.liberion.idleRestartJob {
      service = "amp-runner";
      kind = "amp";
      inherit wrapper;
      extraArgs = [
        "--log-file"
        log
      ];
    })
  ];
}
