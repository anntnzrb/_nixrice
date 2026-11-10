{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types)
    attrsOf
    nullOr
    oneOf
    str
    path
    ;
  inherit (lib) concatStringsSep;

  cfg = config.liberion.desktop.skhd;

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
  options.liberion.desktop.skhd = {
    keybindings = mkOpt' (attrsOf (
      nullOr (oneOf [
        str
        path
      ])
    )) { };
  };

  config.services.skhd = {
    enable = true;
    inherit skhdConfig;
  };
}
