{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    brave
    essentials
    safari
    tailscale
    tinycast
    ui
    yashiki
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
