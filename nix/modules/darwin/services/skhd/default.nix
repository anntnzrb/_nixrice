{ config
, lib
, namespace
, ...
}: with lib;
let
  cfg = config.${namespace}.services.skhd;

  # helpers
  keybindingsStr = concatStringsSep "\n" (mapAttrsToList
    (hotkey: command:
      optionalString (command != null) ''
        ${hotkey} : ${command}
      '')
    cfg.keybindings);
in
{
  options.${namespace}.services.skhd = with lib.${namespace}; {
    enable = mkOptBool';

    keybindings = with types; mkOpt' (attrsOf (nullOr (oneOf [ str path ]))) { };
  };

  config = mkIf cfg.enable {
    services.skhd = {
      enable = true;

      skhdConfig = concatStringsSep "\n" [ keybindingsStr ];
    };
  };
}
