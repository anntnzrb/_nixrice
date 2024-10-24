{ config, ... }:
let
  _cfg = config.liberion.boot;
in
{
  config = {
    boot = {
      consoleLogLevel = 3;
      tmp.cleanOnBoot = true;
    };
  };
}
