import ../../../toggle.nix "shells.fish" (_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting # disable greeting
    '';
  };
})
