{ lib, ... }: {
  programs.fish = {
    enable = true;
    # first, so a machine's own interactiveShellInit follows it
    interactiveShellInit = lib.mkBefore ''
      set -g fish_greeting # disable greeting
    '';
  };
}
