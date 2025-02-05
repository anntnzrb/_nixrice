{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptBool'
    ;
  inherit (lib.types)
    attrsOf
    nullOr
    oneOf
    str
    path
    ;
  inherit (lib) concatStringsSep;

  cfg = config.${namespace}.services.skhd;

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
  options.${namespace}.services.skhd = {
    enable = mkOptBool';

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
