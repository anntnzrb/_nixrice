{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.fs) getModuleFiles;

  cfg = config.${namespace}.cli.espanso;
in
{
  imports = getModuleFiles { path = ./matches; };

  options.${namespace}.cli.espanso = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.espanso = {
      inherit (cfg) enable;
    };
  };
}
