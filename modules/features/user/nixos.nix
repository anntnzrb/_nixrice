{ lib, ... }: { users.users.${lib.liberion.identity.user}.isNormalUser = true; }
