{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.simple-mtpfs;
in
{

  options.${namespace}.cli.simple-mtpfs = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.simple-mtpfs ]; };
}
