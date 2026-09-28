{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    sshd
    user
  ];

  clan.core.deployment.requireExplicitUpdate = true;

  system.stateVersion = "22.05";
}
