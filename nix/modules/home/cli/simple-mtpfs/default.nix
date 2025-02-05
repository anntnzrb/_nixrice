{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.cli.simple-mtpfs;
in
{

  options.${namespace}.cli.simple-mtpfs = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.simple-mtpfs ]; };
}
