{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.desktop.obs;
in
{
  options.${namespace}.desktop.obs = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { programs.obs-studio.enable = true; };
}
