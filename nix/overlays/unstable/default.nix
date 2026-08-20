{ channels, ... }: _final: _prev: {
  inherit (channels.nixpkgs-unstable)
    aerospace
    aider-chat
    bun
    emacs-macport
    lazygit
    vscode
    yashiki
    zed-editor
    ;
}
