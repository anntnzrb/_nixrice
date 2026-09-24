{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  inherit (lib.types) str;
in
{
  options.${namespace}.user = {
    enable = mkOptDisabled';
    name = mkOpt' str "annt";
  };
}
