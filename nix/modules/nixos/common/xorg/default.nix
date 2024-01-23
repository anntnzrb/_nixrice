{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    keyboard = {
      layout = mkOpt' str "us";
      model = mkOpt' str "pc104";
      variant = mkOpt' str "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      autorun = false;
      displayManager.startx.enable = true;

      xkb = {
        inherit (cfg.keyboard) layout model variant;
      };
    };
  };
}
