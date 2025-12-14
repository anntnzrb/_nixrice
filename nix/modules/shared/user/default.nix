{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptEnabled'
    ;
  inherit (lib.types) str;
in
{
  options.${namespace}.user = {
    enable = mkOptEnabled';
    name = mkOpt' str "annt";
  };
}
