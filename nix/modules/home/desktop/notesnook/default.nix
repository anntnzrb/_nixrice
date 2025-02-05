{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.desktop.notesnook;
in
{
  options.${namespace}.desktop.notesnook = {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.notesnook ];
  };
}
