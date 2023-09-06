{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.cli.nnn;
in {
  options.liberion.cli.nnn = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    programs.nnn = {
      enable = true;
      package = pkgs.nnn.override {withNerdIcons = true;};
    };

    home.packages = [pkgs.nerdfonts];
  };
}
