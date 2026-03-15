{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.${namespace}.fs) getModuleFiles;
  inherit (lib) range;
  inherit (lib.types)
    int
    listOf
    ;

  cfg = config.${namespace}.desktop.window-managers.darwin.aerospace;
in
{
  imports = getModuleFiles {
    path = ./.;
    ignore = [ "lib.nix" ];
  };

  options.${namespace}.desktop.window-managers.darwin.aerospace = {
    enable = mkOptDisabled';
    modifier = mkOpt' lib.types.str "alt";
    workspaceRange = mkOpt' (listOf int) (range 0 9);
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "${namespace}.desktop.window-managers.darwin.aerospace is only supported on Darwin.";
      }
    ];

    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      userSettings = {
        start-at-login = false;
        after-login-command = [ ];
      };
    };
  };
}
