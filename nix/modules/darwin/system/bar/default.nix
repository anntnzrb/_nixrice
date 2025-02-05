{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

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
