{ config
, lib
, pkgs
, namespace
, ...
}:
let
  cfg = config.${namespace}.desktop.notesnook;
in
{
  options.${namespace}.desktop.notesnook = with lib.${namespace}; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.notesnook ];
  };
}
