import ../../../toggle.nix "editors.vscode" (
  { pkgs, ... }:
  let
    inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  in
  {
    programs.vscode = {
      enable = true;

      package = if isDarwin then null else pkgs.vscode;

      # extensions can be installed or updated manually
      mutableExtensionsDir = true;
    };

    home.packages = [ pkgs.victor-mono ];
  }
)
