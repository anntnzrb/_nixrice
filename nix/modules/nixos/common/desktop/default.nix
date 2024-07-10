{ lib
, config
, ...
}:
let
  cfg = config.liberion.common.desktop;
in
{
  options.liberion.common.desktop = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;
    security.polkit.enable = true;
  };
}
