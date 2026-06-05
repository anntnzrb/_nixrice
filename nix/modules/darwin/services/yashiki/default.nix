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
  homeDir = "/Users/${config.system.primaryUser}";

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

        ${namespace}.homebrew = on;

        homebrew = {
          taps = [ "typester/yashiki" ];
          casks = [
            {
              name = "yashiki";
            }
          ];
        };

        system.activationScripts.postActivation.text = lib.mkAfter ''
          config_dir="${homeDir}/.config/yashiki"
          config_file="$config_dir/init"

          mkdir -p "$config_dir"
          ln -snf "${initScript}" "$config_file"
          chown -h ${config.system.primaryUser}:staff "$config_file"
          /usr/bin/xattr -dr com.apple.quarantine /Applications/Yashiki.app >/dev/null 2>&1 || :
        '';
      }
      // mkAgent {
        name = "yashiki";
        managedBy = "${namespace}.desktop.window-managers.darwin.yashiki.enable";
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
    ))
  ];
}
