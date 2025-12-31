{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' getModuleFiles';

  cfg = config.${namespace}.cli.espanso;
in
{
  imports = getModuleFiles' ./matches;

  options.${namespace}.cli.espanso = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.espanso = {
      inherit (cfg) enable;
    };
  };
}
