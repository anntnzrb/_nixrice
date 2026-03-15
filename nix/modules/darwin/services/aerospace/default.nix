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
  yashikiCfg = config.${namespace}.desktop.window-managers.darwin.yashiki;
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
        assertion = !yashikiCfg.enable;
        message = "${namespace}.desktop.window-managers.darwin.aerospace cannot be enabled together with ${namespace}.desktop.window-managers.darwin.yashiki.";
      }
    ];

    services.aerospace = {
      enable = true;
      package = pkgs.aerospace;
      settings = {
        start-at-login = false;
        after-login-command = [ ];
      };
    };

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
