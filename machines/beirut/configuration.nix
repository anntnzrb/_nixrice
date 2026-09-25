{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    aerospace
    raycast
    tailscale
    ui
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  determinateNix.customSettings = {
    # nix-darwin's nix module is disabled on darwin
    # (Determinate Nix owns nix.conf)
    # so these must go through the determinate module to be live.
    max-jobs = 10;
    cores = 8;
  };

  liberion = {
    # add munich once it runs NixOS with clan sshd (see clan.nix)
    nix.builders.oulu = 12;
    system.ui.menuBar.hide = false;
  };
}
