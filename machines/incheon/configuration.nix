{ inputs, ... }: {
  imports = [ inputs.self.darwinModules.ui ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings = {
    max-jobs = 8;
    cores = 4;
  };

  liberion = {
    system.ui.menuBar.hide = true;
    homebrew.apps = [
      "obs"
      "rustdesk"
      "vlc"
      "vscode"
    ];
  };
}
