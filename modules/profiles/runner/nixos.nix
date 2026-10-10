{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    amp-runner
    podman
  ];
}
