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
    nix = {
      # remote x86_64-linux builders this Mac may use; munich (personal) is
      # the default, oulu (work) only when a command asks for it
      builders = {
        munich = 12;
        oulu = 12;
      };
      defaultBuilders = [ "munich" ];
    };
    system.ui.menuBar.hide = false;
  };
}
