{ inputs, lib, ... }: {
  imports = with inputs.self.darwinModules; [
    dock
    finder
    (lib.liberion.darwin.homebrewApps [
      "bitwarden"
      "orbstack"
      "whatsapp"
    ])
    keyboard
    trackpad
  ];

}
