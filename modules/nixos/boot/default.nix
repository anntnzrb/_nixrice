{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptEnabled';

  cfg = config.liberion.boot;
in
{
  options.liberion.boot = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 3;
      tmp.cleanOnBoot = true;
    };
  };
}
