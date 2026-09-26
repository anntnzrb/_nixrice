{ lib, ... }: {
  networking.networkmanager.enable = true;
  users.users.${lib.liberion.identity.user}.extraGroups = [ "networkmanager" ];
}
