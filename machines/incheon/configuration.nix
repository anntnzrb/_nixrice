{ lib, self, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ self.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.users.annt.imports = [ ./home.nix ];

  nix.settings = {
    max-jobs = 8;
    cores = 4;
  };

  liberion = {
    suites.desktop = on;

    system = {
      ui = on // {
        menuBar.hide = true;
      };
    };

    programs = {
      obs = on;
      rustdesk = on;
      vlc = on;
      vscode = on;
    };
  };
}
