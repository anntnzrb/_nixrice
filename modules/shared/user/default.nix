{ lib, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) str;
in
{
  options.liberion.user = {
    enable = mkOptDisabled';
    name = mkOpt' str lib.liberion.identity.user;
  };
}
