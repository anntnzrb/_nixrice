{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.ghostty;

  mod = "programs/ghostty.nix";
in
with lib.${namespace};
{
  disabledModules = [ mod ];
  imports = [
    (import (inputs.home-manager-unstable + "/modules/${mod}"))
  ];

  options.${namespace}.desktop.terminal-emulators.ghostty = {
    enable = mkOptBool';
    font = with lib.types; {
      size = mkOpt' ints.unsigned 10;
      family = mkOpt' str "ZedMono Nerd Font Mono";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        theme = "catppuccin-frappe";

        font-size = cfg.font.size;
        font-family = cfg.font.family;
        font-family-bold = cfg.font.family;
        font-family-italic = cfg.font.family;
        font-family-bold-italic = cfg.font.family;
      };

      installBatSyntax = true;

      # these will most likely be set to to true by default
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
  };
}
