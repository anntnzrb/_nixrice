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
    mkOptBool'
    ;

  cfg = config.${namespace}.desktop.terminal-emulators.rio;
in
{
  imports = [
    ./window.nix
    ./ui.nix
    ./theme.nix
    ./font.nix
    ./bind.nix
  ];

  options.${namespace}.desktop.terminal-emulators.rio = {
    enable = mkOptBool';
    font.size = mkOpt' lib.types.int 15;
  };

  config.programs.rio = lib.mkIf cfg.enable {
    inherit (cfg) enable;
    settings = {
      option-as-alt = lib.optionals pkgs.stdenvNoCC.hostPlatform.isDarwin "both";
      use-fork = false; # prefer clean process
      confirm-before-quit = false;

      editor = {
        program = "${config.home.sessionVariables.EDITOR}";
        args = [ ];
      };
    };
  };
}
