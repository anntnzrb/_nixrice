{ lib, pkgs, ... }:
let
  inherit (lib.liberion.identity) user;
  shell = pkgs.bashInteractive;
in
{
  programs.bash.enable = true;

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
