{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      packages = {
        casks = mkOpt' (listOf str) [ ];
      };
    };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };

      inherit (cfg.packages) casks;
    };
  };
}
