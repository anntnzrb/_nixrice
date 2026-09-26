{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    aerospace
    essentials
    raycast
    tailscale
    ui
    zsh
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
    system.ui.menuBar.hide = false;
  };
}
