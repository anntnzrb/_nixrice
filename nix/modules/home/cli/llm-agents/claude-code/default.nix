{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.llmAgents.claude-code;
in
{
  options.${namespace}.cli.llmAgents.claude-code = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.sessionPath = [ "${config.home.homeDirectory}/.claude/bin" ];
  };
}
