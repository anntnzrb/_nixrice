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
  inherit (config.home) homeDirectory profileDirectory;

  cfg = config.${namespace}.services.t3;
  logDir = "${homeDirectory}/.t3/userdata/logs";
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
    }
    // mkAgent {
      name = "t3";
      serviceConfig = {
        ProgramArguments = [
          (lib.getExe' pkgs.nodejs "npx")
          "--yes"
          "t3@nightly"
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
