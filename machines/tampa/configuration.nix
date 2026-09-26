{ inputs, ... }: {
  imports = [ inputs.self.nixosModules.wsl ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
