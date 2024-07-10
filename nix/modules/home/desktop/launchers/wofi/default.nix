{ config, lib, ... }:
let
  cfg = config.liberion.desktop.launchers.wofi;
in
{
  options.liberion.desktop.launchers.wofi = with lib.liberion; {
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
