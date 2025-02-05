{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.system.bar;
in
{
  options.${namespace}.system.bar = {
    sketchybar.enable = mkOptBool';
  };

  config = {
    services.sketchybar = lib.mkIf cfg.sketchybar.enable {
      enable = true;
    };
  };
}
