{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    on
    ;
  inherit (lib.${namespace}.launchd.darwin) mkAgent;

  cfg = config.${namespace}.services.yashiki;
  aerospaceCfg = config.${namespace}.services.aerospace;
in
{
  options.${namespace}.services.yashiki = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
    };
  };

  config = lib.mkIf cfg.enable (
    {
      warnings = [
        "${namespace}.services.yashiki is a legacy compatibility shim. Prefer ${namespace}.desktop.window-managers.darwin.yashiki."
      ];

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
