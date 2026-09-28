{ lib, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.mkBefore ''
      set -g fish_greeting
    '';
  };
}
