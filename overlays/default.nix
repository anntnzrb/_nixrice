{ inputs }:
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  # unstable package set for fast-moving tools
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  rice = final.callPackage ../packages/rice { };

  bun = inputs.bun-overlay.packages.${system}.bun.overrideAttrs (old: {
    meta = (old.meta or { }) // {
      mainProgram = "bun";
    };
  });

  inherit (final.unstable)
    aerospace
    aider-chat
    emacs-macport
    lazygit
    vscode
    yashiki
    zed-editor
    ;
}
