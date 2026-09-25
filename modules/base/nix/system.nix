# Nix baseline shared by NixOS and nix-darwin; each platform module applies
# `caches` its own way (nix.settings vs Determinate's nix.custom.conf).
{ lib, ... }:
let
  inherit (lib.liberion.module) mkOpt';
in
{
  options.liberion.nix = {
    # substituter URL -> trusted public key
    caches = mkOpt' (lib.types.attrsOf lib.types.str) {
      "https://nix-community.cachix.org" =
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      "https://cache.numtide.com" =
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
      "https://devenv.cachix.org" =
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      "https://anntnzrb.cachix.org" =
        "anntnzrb.cachix.org-1:hG29RyjX45a9q1nZqdvOJUQ6nRDG/Jj4yt2d1dpWCgE=";
    };
  };

  config.documentation = {
    doc.enable = false;
    info.enable = false;
  };
}
