{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.simple-mtpfs;
in
{

  options.${namespace}.cli.simple-mtpfs = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.simple-mtpfs ]; };
}
