{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.obs;
in
{
  options.${namespace}.desktop.obs = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = { inherit (cfg) enable; };
  };
}
