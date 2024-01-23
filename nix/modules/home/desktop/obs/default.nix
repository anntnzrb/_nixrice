{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.obs;
in
{
  options.liberion.desktop.obs = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio.enable = true;
  };
}
