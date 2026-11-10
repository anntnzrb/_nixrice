{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    amp
    podman
  ];
}
