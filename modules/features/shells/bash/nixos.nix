{ lib, pkgs, ... }: {
  users.users.${lib.liberion.identity.user}.shell = pkgs.bashInteractive;
}
