{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.network.ssh;
in
{
  options.${namespace}.network.ssh = {
    enable = mkOptDisabled';
  };

  config.programs.ssh = lib.mkIf cfg.enable {
    enable = true;
    addKeysToAgent = "confirm 1h";
  };
}
