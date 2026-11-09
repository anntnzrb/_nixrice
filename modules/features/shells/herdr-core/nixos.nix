{ lib, ... }: { users.users.${lib.liberion.identity.user}.linger = true; }
