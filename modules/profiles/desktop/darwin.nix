{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    dock
    finder
    homebrew
    keyboard
    trackpad
  ];

  liberion.homebrew.apps = [
    "bitwarden"
    "orbstack"
    "whatsapp"
  ];
}
