{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.launchers.wofi;
in
{
  options.${namespace}.desktop.launchers.wofi = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.wofi = {
      inherit (cfg) enable;

      settings = {
        location = "bottom-right";
      };
    };
  };
}
