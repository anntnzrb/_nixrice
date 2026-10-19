{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    paseo
    t3
  ];
}
