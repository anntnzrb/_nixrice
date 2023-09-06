{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.flameshot;
in {
  options.liberion.desktop.flameshot = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    services.flameshot = {
      enable = true;
    };
  };
}
