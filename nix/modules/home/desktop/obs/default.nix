{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.obs;
in
{
  options.liberion.desktop.obs = {
    enable = lib.mkEnableOption "obs";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio.enable = true;
  };
}
