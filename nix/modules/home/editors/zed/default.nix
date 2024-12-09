{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.zed;
in
{
  options.${namespace}.editors.zed = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zed-editor ];
  };
}
