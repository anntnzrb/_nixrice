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
    max-jobs = 5;
    cores = 4;
  };

  liberion = {
    system.ui.menuBar.hide = false;
  };
}
