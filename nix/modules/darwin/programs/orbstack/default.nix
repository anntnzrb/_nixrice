{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  cfg = config.${namespace}.programs.orbstack;
in
{
  options.${namespace}.programs.orbstack = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "orbstack" ];
  };
}
