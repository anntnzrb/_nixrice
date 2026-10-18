{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    aerospace
    bash
    brave
    essentials
    firefox
    ghostty
    safari
    stremio
    t3
    tailscale
    tinycast
    ui
  ];

  liberion.ai.t3.desktop = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  determinateNix.customSettings = {
    max-jobs = 5;
    cores = 4;
  };
}
