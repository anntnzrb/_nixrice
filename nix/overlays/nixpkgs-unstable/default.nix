{ channels, inputs, ... }: _final: prev: {
  bun =
    inputs.bun-overlay.packages.${prev.stdenv.hostPlatform.system}.bun.overrideAttrs
      (old: {
        meta = (old.meta or { }) // {
          mainProgram = "bun";
        };
      });

  inherit (channels.nixpkgs-unstable)
    aider-chat
    aerospace
    emacs-macport
    lazygit
    vscode
    yashiki
    zed-editor
    ;
}
