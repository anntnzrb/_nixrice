{ lib, config, ... }:
let
  cfg = config.liberion.nix;
in
{
  config = {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = lib.attrNames cfg.caches;
        trusted-public-keys = lib.attrValues cfg.caches;
        trusted-users = [
          "root"
          "@wheel"
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        randomizedDelaySec = "45min";
      };
    };

    documentation.man.cache.enable = true;
  };
}
