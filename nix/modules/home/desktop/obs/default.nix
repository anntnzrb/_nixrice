{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.obs;
in
{
  options.${namespace}.desktop.obs = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { programs.obs-studio.enable = true; };
}
