{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.cli.direnv;
in {
  options.liberion.cli.direnv = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
