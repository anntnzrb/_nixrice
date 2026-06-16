{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-unstable)
    bun

    aider-chat
    emacs-macport
    vscode
    zed-editor
    ;
}
