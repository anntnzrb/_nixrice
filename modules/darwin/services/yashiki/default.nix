{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';
  inherit (lib.liberion.fs) getModuleFiles;
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.window-managers.darwin.yashiki;
  aerospaceCfg = config.liberion.desktop.window-managers.darwin.aerospace;
  yashikiPkg = pkgs.yashiki;
  yashikiLib = import ./lib.nix { inherit lib; };

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
    ignore = [
      "lib.nix"
      "rules.nix"
    ];
  };

  options.liberion.desktop.window-managers.darwin.yashiki = {
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
    { _module.args.yashikiLib = yashikiLib; }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !aerospaceCfg.enable;
          message = "liberion.desktop.window-managers.darwin.yashiki cannot be enabled together with liberion.desktop.window-managers.darwin.aerospace.";
        }
      ];

      liberion.desktop.window-managers.darwin.yashiki._sections.rules =
        yashikiLib.mkRules (import ./rules.nix);

      environment.systemPackages = [ yashikiPkg ];

      home-manager.users.${config.system.primaryUser}.xdg.configFile."yashiki/init" =
        {
          source = initScript;
          executable = true;
        };

      launchd.user.agents.yashiki = {
        managedBy = "liberion.desktop.window-managers.darwin.yashiki.enable";
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
      };
    })
  ];
}
