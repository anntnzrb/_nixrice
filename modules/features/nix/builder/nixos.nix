# Accepts remote builds from the owner (beirut sends it x86_64-linux work).
{ lib, ... }: { nix.settings.trusted-users = [ lib.liberion.identity.user ]; }
