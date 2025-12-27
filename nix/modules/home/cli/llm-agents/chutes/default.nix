{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.llmAgents.chutes;
in
{
  options.${namespace}.cli.llmAgents.chutes = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.${namespace}.chutes ];
  };
}
