{ inputs, ... }: {
  imports = [ inputs.self.nixosModules.user ];

  system.stateVersion = "22.05";
}
