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
    max-jobs = 10;
    cores = 8;
  };

  liberion = {
    system.ui.menuBar.hide = false;
  };
}
