{ inputs, ... }: {
  imports = with inputs.self.homeModules; [
    ghostty
    zsh
  ];
}
