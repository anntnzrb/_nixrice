{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.common.desktop;
in
{
  options.${namespace}.common.desktop = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;
    security.polkit.enable = true;
  };
}
