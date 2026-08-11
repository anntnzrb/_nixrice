{ ... }: {
  imports = [
    ./foundation/options.nix
    ./foundation/discovery.nix
    ./foundation/contexts.nix
    ./targets/systems.nix
    ./targets/homes.nix
    ./outputs/artifacts.nix
  ];
}
