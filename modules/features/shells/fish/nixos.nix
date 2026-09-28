{ lib, pkgs, ... }: {
  programs.fish.enable = true;
  users.users.${lib.liberion.identity.user}.shell = pkgs.fish;
}
