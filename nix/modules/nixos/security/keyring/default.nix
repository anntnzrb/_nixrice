{
  lib,
  config,
  ...
}: let
  cfg = config.liberion.security.keyring;
in {
  config = {
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;
  };
}
