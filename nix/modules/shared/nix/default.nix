{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptEnabled'
    off
    on
    ;
  inherit (lib) attrNames attrValues;
  inherit (lib.types) attrsOf listOf str;

  cfg = config.${namespace}.nix;

  cachesType = attrsOf str;
  stringListType = listOf str;

  # Attrset substituter URL -> public key
  cachesDefault = {
    "https://nix-community.cachix.org" =
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    "https://cache.numtide.com" =
      "cache.numtide.com-1:Po2KLsCXwbalByBWLwvJCBs1l1pVGFeSCY+UNrDP3Uw=";
    "https://devenv.cachix.org" =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    "https://anntnzrb.cachix.org" =
      "anntnzrb.cachix.org-1:hG29RyjX45a9q1nZqdvOJUQ6nRDG/Jj4yt2d1dpWCgE=";
  };
in
{
  options.${namespace}.nix = {
    enable = mkOptEnabled';

    caches = mkOpt' cachesType cachesDefault;
    substituters = mkOpt' stringListType (attrNames cfg.caches);
    trustedPublicKeys = mkOpt' stringListType (attrValues cfg.caches);
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        inherit (cfg) substituters;
        trusted-public-keys = cfg.trustedPublicKeys;
      };

      gc.automatic = pkgs.stdenvNoCC.hostPlatform.isLinux;
    };

    documentation = {
      doc = off;
      info = off;
      man = on;
    };
  };
}
