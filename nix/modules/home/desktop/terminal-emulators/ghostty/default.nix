# https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
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
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.types)
    nullOr
    package
    str
    ints
    ;

  cfg = config.${namespace}.desktop.terminal-emulators.ghostty;

  fonts = {
    iosevka-comfy-motion = {
      name = "Iosevka Comfy Motion";
      pkg = pkgs.iosevka-comfy.comfy-motion;
    };
  };

  mod = "programs/ghostty.nix";
in
{
  disabledModules = [ mod ];
  imports = [ (import "${inputs.home-manager-unstable}/modules/${mod}") ];

  options.${namespace}.desktop.terminal-emulators.ghostty = {
    enable = mkOptDisabled';

    package = mkOpt' (nullOr package) pkgs.ghostty;

    font = {
      size = mkOpt' ints.unsigned 10;
      family = mkOpt' str fonts.iosevka-comfy-motion.name;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.attrsets.mapAttrsToList (_: font: font.pkg) fonts;

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

      installBatSyntax = lib.mkIf (cfg.package != null) true;

      # these will most likely be set to to true by default
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
  };
}
