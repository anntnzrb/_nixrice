{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    sshd
    user
  ];

  system.stateVersion = "22.05";
}
