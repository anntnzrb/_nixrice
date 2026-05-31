{
  lib,
  pkgs,
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
  inherit (lib.${namespace}.fs) getModuleFiles;
  inherit (lib.types) listOf str;

  cfg = config.${namespace}.desktop.window-managers.darwin.yashiki;
  aerospaceCfg = config.${namespace}.desktop.window-managers.darwin.aerospace;

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

  runner = pkgs.writeShellScript "yashiki-start" ''
    set -eu

    config_dir="$HOME/.config/yashiki"
    config_file="$config_dir/init"

    mkdir -p "$config_dir"
    ln -snf "${initScript}" "$config_file"

    exec /Applications/Yashiki.app/Contents/MacOS/yashiki start
  '';
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
        managedBy = "${namespace}.desktop.window-managers.darwin.yashiki.enable";
        serviceConfig = {
          ProgramArguments = [
            runner
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
    ))
  ];
}
