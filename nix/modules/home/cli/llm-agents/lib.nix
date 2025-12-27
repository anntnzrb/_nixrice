{
  lib,
  namespace,
  pkgs,
  config,
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  mkAgent =
    {
      name,
      attr,
    }:
    let
      cfg = config.${namespace}.cli.llmAgents.${name};

      wrapper = pkgs.writeShellApplication {
        inherit name;
        text = ''
          exec ${pkgs.runtimeShell} ${./llm-agent-wrapper.sh} ${attr} "$@"
        '';
      };
    in
    {
      options.${namespace}.cli.llmAgents.${name} = {
        enable = mkOptDisabled';
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ wrapper ];
      };
    };
in
mkAgent
