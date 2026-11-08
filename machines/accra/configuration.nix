{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    bash
    essentials
    wsl
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
