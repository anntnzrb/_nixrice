# https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.ghostty;

  mod = "programs/ghostty.nix";
in
{
  disabledModules = [ mod ];
  imports = [
    (import (inputs.home-manager-unstable + "/modules/${mod}"))
  ];

  options.${namespace}.desktop.terminal-emulators.ghostty = with lib.${namespace}; {
    enable = mkOptBool';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ghostty;
      description = "Ghostty terminal package";
    };

    font = with lib.types; {
      size = mkOpt' ints.unsigned 10;
      family = mkOpt' str "ZedMono Nerd Font Mono";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      inherit (cfg) enable package;
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
