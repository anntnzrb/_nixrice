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

  cfg = config.${namespace}.programs.aldente;
in
{
  options.${namespace}.programs.aldente = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "aldente" ];
  };
}
