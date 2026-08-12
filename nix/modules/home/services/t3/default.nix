{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.launchd.home) mkAgent;
  inherit (lib.${namespace}.npm) mkLauncher;
  inherit (config.home) homeDirectory profileDirectory;

  cfg = config.${namespace}.services.t3;
  logDir = "${homeDirectory}/.t3/userdata/logs";

  /**
    Launch the t3 CLI from the npm registry, pinned to the
    `nightly` dist-tag, via the shared npm launcher.

    # Type

    ```
    t3Wrapper :: Derivation
    ```
  */
  t3Wrapper = mkLauncher pkgs {
    name = "t3";
    tool = "t3";
    package = "t3";
    bin = "t3";
    distTag = "nightly";
    smokeCheck = "--version";
  };
in
{
  options.${namespace}.services.t3.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable (
    {
      home.activation.t3LogDirectory =
        config.lib.dag.entryAfter [ "writeBoundary" ]
          ''
            run mkdir -p ${lib.escapeShellArg logDir}
          '';
      home.packages = [ t3Wrapper ];
    }
    // mkAgent {
      name = "t3";
      serviceConfig = {
        ProgramArguments = [
          "${t3Wrapper}/bin/t3"
          "serve"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        EnvironmentVariables = {
          HOME = homeDirectory;
          PATH = "${profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        StandardOutPath = "${logDir}/launchd-serve.out.log";
        StandardErrorPath = "${logDir}/launchd-serve.err.log";
      };
    }
  );
}
