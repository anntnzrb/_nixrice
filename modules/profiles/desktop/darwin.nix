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

  # zsh as an interactive shell; this is a forced default
  # customization is done via hm
  programs.zsh.enable = true;

  liberion.homebrew.apps = [
    "bitwarden"
    "orbstack"
    "whatsapp"
  ];
}
