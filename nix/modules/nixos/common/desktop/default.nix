{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.common.desktop;
in
{
  options.${namespace}.common.desktop = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring = on;
    programs.dconf = on;
    security.polkit = on;
  };
}
