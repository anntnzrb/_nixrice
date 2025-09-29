{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.boot;
in
{
  options.${namespace}.boot = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 3;
      tmp.cleanOnBoot = true;
    };
  };
}
