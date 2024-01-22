{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib;{
    enable = lib.mkEnableOption "xorg defaults";


    keyboard = {
      layout = mkOption {
        type = types.str;
        default = "us";
      };

      model = mkOption {
        type = types.str;
        default = "pc104";
      };

      variant = mkOption {
        type = types.commas;
        default = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;

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
