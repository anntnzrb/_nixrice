{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.desktop.launchers.wofi;
in
{
  options.${namespace}.desktop.launchers.wofi = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.wofi = {
      enable = true;

      settings = {
        location = "bottom-right";
      };
    };
  };
}
