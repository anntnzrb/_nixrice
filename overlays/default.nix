{ inputs }:
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  inherit (final.unstable)
    aerospace
    bun
    lazygit
    vscode
    yashiki
    zed-editor
    ;
}
