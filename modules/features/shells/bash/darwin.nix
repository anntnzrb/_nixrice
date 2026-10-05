{ lib, pkgs, ... }:
let
  inherit (lib.liberion.identity) user;
  shell = pkgs.bashInteractive;
in
{
  programs.bash.enable = true;

  environment.etc.profile = {
    text = ''
      if [ "''${BASH-no}" != "no" ]; then
        [ -r /etc/bashrc ] && . /etc/bashrc
      fi
    '';
    # Stock macOS /etc/profile, whose path_helper call moves /usr/bin ahead of Nix.
    knownSha256Hashes = [
      "a3fe9f414586c0d3cacbe3b6920a09d8718e503bca22e23fef882203bf765065"
    ];
  };

  users = {
    knownUsers = [ user ];
    users.${user} = {
      # macOS assigns 501 to the first account; nix-darwin skips the user on a mismatch.
      uid = 501;
      inherit shell;
    };
  };

  liberion.darwin.owned.shell = "/run/current-system/sw${shell.shellPath}";
}
