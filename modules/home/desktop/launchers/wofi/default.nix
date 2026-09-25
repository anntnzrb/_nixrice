{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.launchers.wofi;
in
{
  options.liberion.desktop.launchers.wofi = {
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
