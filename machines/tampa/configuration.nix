{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    sshd
    user
    wsl
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
