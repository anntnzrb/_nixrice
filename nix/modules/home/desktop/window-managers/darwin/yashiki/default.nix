{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filter
    ;
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.launchd.home) mkAgent;
  inherit (lib.${namespace}.fs) getModuleFiles;
  inherit (lib.types) listOf str;

  cfg = config.${namespace}.desktop.window-managers.darwin.yashiki;

  scriptSections = filter (lines: lines != [ ]) [
    cfg._sections.layout
    cfg._sections.bindings
    cfg._sections.rules
  ];

  script = concatStringsSep "\n\n" (
    builtins.map (concatStringsSep "\n") scriptSections
  );
in
{
  imports = getModuleFiles {
    path = ./.;
    ignore = [ "lib.nix" ];
  };

  options.${namespace}.desktop.window-managers.darwin.yashiki = {
    enable = mkOptDisabled';

    _sections = {
      layout = lib.mkOption {
        type = listOf str;
        default = [ ];
        internal = true;
      };

      bindings = lib.mkOption {
        type = listOf str;
        default = [ ];
        internal = true;
      };

      rules = lib.mkOption {
        type = listOf str;
        default = [ ];
        internal = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "${namespace}.desktop.window-managers.darwin.yashiki is only supported on Darwin.";
        }
      ];

      xdg.configFile."yashiki/init" = {
        source = pkgs.writeShellScript "yashiki-init" script;
        executable = true;
      };
    }
    // mkAgent {
      name = "yashiki";
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
          PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    }
  );
}
