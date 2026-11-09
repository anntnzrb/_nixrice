{ inputs, lib, ... }: {
  imports = with inputs.self.darwinModules; [
    dock
    finder
    (lib.liberion.darwin.homebrewApps [ "orbstack" ])
    keyboard
    trackpad
  ];

}
