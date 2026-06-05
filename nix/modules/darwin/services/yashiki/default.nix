{
  lib,
  pkgs,
  inputs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;
  inherit (lib.${namespace}.launchd.darwin) mkAgent;
  inherit (lib.${namespace}.fs) getModuleFiles;
  inherit (lib.types) listOf str;

  cfg = config.${namespace}.desktop.window-managers.darwin.yashiki;
  aerospaceCfg = config.${namespace}.desktop.window-managers.darwin.aerospace;
  yashikiPkg = inputs.nurpkgs.packages.${pkgs.stdenv.hostPlatform.system}.yashiki;

  scriptSections = lib.filter (lines: lines != [ ]) [
    cfg._sections.layout
    cfg._sections.bindings
    cfg._sections.rules
  ];

  initScript = pkgs.writeShellScript "yashiki-init" (
    lib.concatStringsSep "\n\n" (
      builtins.map (lib.concatStringsSep "\n") scriptSections
    )
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

  config = lib.mkMerge [
    {
      _module.args.yashikiLib = import ./lib.nix { inherit lib; };
    }
    (lib.mkIf cfg.enable (
      {
        assertions = [
          {
            assertion = !aerospaceCfg.enable;
            message = "${namespace}.desktop.window-managers.darwin.yashiki cannot be enabled together with ${namespace}.desktop.window-managers.darwin.aerospace.";
          }
        ];

        environment.systemPackages = [ yashikiPkg ];

        home-manager.users.${config.system.primaryUser}.xdg.configFile."yashiki/init" =
          {
            source = initScript;
            executable = true;
          };

      }
      // mkAgent {
        name = "yashiki";
        managedBy = "${namespace}.desktop.window-managers.darwin.yashiki.enable";
        serviceConfig = {
          ProgramArguments = [
            "/Applications/Nix Apps/Yashiki.app/Contents/MacOS/yashiki"
            "start"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          LimitLoadToSessionType = [ "Aqua" ];
          EnvironmentVariables = {
            PATH = "${yashikiPkg}/bin:${config.environment.systemPath}";
          };
        };
      }
    ))
  ];
}
