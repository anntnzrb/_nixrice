{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    aerospace
    bash
    brave
    essentials
    safari
    tailscale
    tinycast
    ui
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
