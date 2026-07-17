{
  channels,
  inputs,
  ...
}:
_final: prev: {
  bun = inputs.bun-overlay.packages.${prev.stdenv.hostPlatform.system}.bun;

  inherit (channels.nixpkgs-unstable)
    aider-chat
    aerospace
    emacs-macport
    vscode
    zed-editor
    ;
}
