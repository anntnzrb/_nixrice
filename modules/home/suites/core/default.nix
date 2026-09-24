{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.core;
in
{
  options.${namespace}.suites.core = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      shells = {
        prompt.starship = on;
        preliminaryMessage.disable = true;
      };
    };
  };
}
