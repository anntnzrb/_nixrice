{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.bun;
in
{
  options.${namespace}.cli.bun = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.bun.enable = true;
  };
}
