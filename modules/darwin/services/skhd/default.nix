{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types)
    attrsOf
    nullOr
    oneOf
    str
    path
    ;
  inherit (lib) concatStringsSep;

  cfg = config.liberion.services.skhd;

  # helpers
  keybindingsStr = concatStringsSep "\n" (
    lib.mapAttrsToList (
      hotkey: command:
      lib.optionalString (command != null) ''
        ${hotkey} : ${command}
      ''
    ) cfg.keybindings
  );

  skhdConfig = concatStringsSep "\n" [ keybindingsStr ];
in
{
  options.liberion.services.skhd = {
    enable = mkOptDisabled';

    keybindings = mkOpt' (attrsOf (
      nullOr (oneOf [
        str
        path
      ])
    )) { };
  };

  config.services.skhd = lib.mkIf cfg.enable {
    inherit (cfg) enable;
    inherit skhdConfig;
  };
}
