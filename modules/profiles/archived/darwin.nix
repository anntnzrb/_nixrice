{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [ sshd ];

  clan.core.deployment.requireExplicitUpdate = true;
}
