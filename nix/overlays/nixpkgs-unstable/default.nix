{
  channels,
  ...
}:
_final: _prev: {
  inherit (channels.nixpkgs-unstable)
    aider-chat
    bun
    emacs-macport
    vscode
    zed-editor
    ;
}
