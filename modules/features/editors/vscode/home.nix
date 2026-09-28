{ pkgs, ... }:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

in
{
  programs.vscode = {
    enable = true;

    package = if isDarwin then null else pkgs.vscode;

    mutableExtensionsDir = true;
  };

  home.packages = [ pkgs.victor-mono ];
}
