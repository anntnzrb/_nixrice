{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.nix;
in
{
  options.${namespace}.nix = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://nix-community.cachix.org"
          "https://devenv.cachix.org"
          "https://anntnzrb.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "anntnzrb.cachix.org-1:hG29RyjX45a9q1nZqdvOJUQ6nRDG/Jj4yt2d1dpWCgE="
        ];
      };

      gc.automatic = true;
    };

    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = true;
    };
  };
}
