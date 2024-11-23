{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.system.bar;
in
{
  options.${namespace}.system.bar = with lib.${namespace}; {
    sketchybar.enable = mkOptBool';
  };

  config = {
    services.sketchybar = lib.mkIf cfg.sketchybar.enable {
      enable = true;
    };
  };
}
