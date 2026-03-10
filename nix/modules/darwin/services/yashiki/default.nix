{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    on
    ;
  inherit (lib.${namespace}.launchd.darwin) mkAgent;

  cfg = config.${namespace}.services.yashiki;
  aerospaceCfg = config.${namespace}.services.aerospace;
in
{
  options.${namespace}.services.yashiki = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable (
    {
      assertions = [
        {
          assertion = !aerospaceCfg.enable;
          message = "${namespace}.services.yashiki cannot be enabled together with ${namespace}.services.aerospace.";
        }
      ];

      ${namespace}.homebrew = on;

      homebrew = {
        taps = [ "typester/yashiki" ];
        casks = [
          {
            name = "yashiki";
            args = {
              no_quarantine = true;
            };
          }
        ];
      };
    }
    // mkAgent {
      name = "yashiki";
      managedBy = "${namespace}.services.yashiki.enable";
      serviceConfig = {
        ProgramArguments = [
          "/Applications/Yashiki.app/Contents/MacOS/yashiki"
          "start"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
        EnvironmentVariables = {
          PATH = "/opt/homebrew/bin:${config.environment.systemPath}";
        };
      };
    }
  );
}
