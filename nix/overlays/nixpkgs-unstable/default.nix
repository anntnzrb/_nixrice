{
  channels,
  ...
}:
_final: _prev: {
  inherit (channels.nixpkgs-unstable)
    vscode
    aider-chat
    zed-editor
    ;
}
