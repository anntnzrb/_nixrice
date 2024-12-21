{
  channels,
  ...
}:
_final: _prev: { inherit (channels.nixpkgs-unstable) zed-editor; }
