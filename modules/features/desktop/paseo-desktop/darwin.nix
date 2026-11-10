{ inputs, lib, ... }: {
  imports = [
    (lib.liberion.darwin.homebrewApps [ "paseo" ])
    inputs.self.darwinModules.paseo
  ];
}
