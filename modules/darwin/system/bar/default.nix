{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.system.bar;
in
{
  options.liberion.system.bar = {
    sketchybar.enable = mkOptDisabled';
  };

  config = {
    services.sketchybar = lib.mkIf cfg.sketchybar.enable {
      inherit (cfg.sketchybar) enable;
    };
  };
}
