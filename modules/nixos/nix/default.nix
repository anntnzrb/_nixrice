{ lib, config, ... }:
let
  cfg = config.liberion.nix;
in
{
  imports = [ (lib.liberion.fs.getFile "modules/shared/nix/default.nix") ];

  config = lib.mkIf cfg.enable {
    nix = {
      settings.trusted-users = [
        "root"
        "@wheel"
      ];

      gc = {
        dates = "weekly";
        randomizedDelaySec = "45min";
      };
    };

    documentation.man.cache.enable = true;
  };
}
