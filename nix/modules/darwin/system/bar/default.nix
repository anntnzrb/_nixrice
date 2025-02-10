{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.system.bar;
in
{
  options.${namespace}.system.bar = {
    sketchybar.enable = mkOptDisabled';
  };

  config = {
    services.sketchybar = lib.mkIf cfg.sketchybar.enable {
      enable = true;
    };
  };
}
