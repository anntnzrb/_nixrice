{
  config,
  lib,
  namespace,
  ...
}:
let
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
  options.${namespace}.services.skhd = with lib.${namespace}; {
    enable = mkOptBool';

    keybindings =
      with lib.types;
      mkOpt' (attrsOf (
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
