{ channels, ... }:
final: prev: {
  inherit (channels.nixpkgs-unstable) vscode-fhs;
}