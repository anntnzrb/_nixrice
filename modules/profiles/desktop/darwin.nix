# Machines tagged `desktop` (macOS).
{ inputs, ... }: {
  imports = with inputs.self.darwinModules; [
    dock
    finder
    homebrew
    keyboard
    sshd
    trackpad
  ];

  liberion.homebrew.apps = [
    "bitwarden"
    "orbstack"
    "whatsapp"
  ];
}
