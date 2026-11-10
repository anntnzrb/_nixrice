{ inputs, lib, ... }: {
  imports = [
    (lib.liberion.darwin.homebrewApps [ "t3-code" ])
    inputs.self.darwinModules.t3
  ];
}
