# fish as the owner's login shell; its Home Manager side is home.nix here.
{ lib, pkgs, ... }: {
  programs.fish.enable = true;
  users.users.${lib.liberion.identity.user}.shell = pkgs.fish;
}
