{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.launchers.wofi;
in
{
  options.liberion.desktop.launchers.wofi = {
    enable = lib.mkEnableOption "wofi";
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
