{ lib, self, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ self.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  home-manager.users.annt.imports = [ ./home.nix ];

  determinateNix.customSettings = {
    # nix-darwin's nix module is disabled on darwin
    # (Determinate Nix owns nix.conf)
    # so these must go through the determinate module to be live.
    max-jobs = 10;
    cores = 8;
  };

  liberion = {
    suites.desktop = on;

    network.tailscale = on;
    programs.raycast = on;
    # add munich once it runs NixOS with clan sshd (see clan.nix)
    nix.builders.oulu = 12;

    desktop.window-managers.darwin.aerospace = on;

    system = {
      ui = on // {
        menuBar.hide = false;
      };
    };

  };
}
