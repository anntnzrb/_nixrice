{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.launchers.wofi;
in
{
  options.${namespace}.desktop.launchers.wofi = with lib.${namespace}; {
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
