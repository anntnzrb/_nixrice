{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.notesnook;
in
{
  options.${namespace}.desktop.notesnook = {
    enable = mkOptDisabled';
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.notesnook ]; };
}
