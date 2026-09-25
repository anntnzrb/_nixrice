{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.common.desktop;
in
{
  options.liberion.common.desktop = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring = on;
    programs.dconf = on;
    security.polkit = on;
  };
}
