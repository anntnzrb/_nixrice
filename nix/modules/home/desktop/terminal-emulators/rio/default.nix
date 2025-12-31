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
    getModuleFiles
    ;

  cfg = config.${namespace}.desktop.terminal-emulators.rio;
in
{
  imports = getModuleFiles { path = ./.; };

  options.${namespace}.desktop.terminal-emulators.rio = {
    enable = mkOptDisabled';
    font.size = mkOpt' lib.types.int 15;
  };

  config.programs.rio = lib.mkIf cfg.enable {
    inherit (cfg) enable;
    settings = {
      option-as-alt = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin "both";
      use-fork = false; # prefer clean process
      confirm-before-quit = false;

      editor = {
        program = "${config.home.sessionVariables.EDITOR}";
        args = [ ];
      };
    };
  };
}
