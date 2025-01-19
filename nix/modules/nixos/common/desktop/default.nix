{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.common.desktop;
in
{
  options.${namespace}.common.desktop = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;
    security.polkit.enable = true;
  };
}
