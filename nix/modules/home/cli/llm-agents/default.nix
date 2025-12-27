{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib)
    mapAttrs'
    nameValuePair
    mkIf
    mkMerge
    ;

  # wrapper-based agents: name -> flake attr mapping
  agents = {
    opencode = "opencode";
    crush = "crush";
    codex = "codex";
    droid = "droid";
    gemini = "gemini-cli";
    goose = "goose-cli";
    kilo = "kilocode-cli";
    qwen = "qwen-code";
  };

  mkAgentOption = name: _: nameValuePair name { enable = mkOptDisabled'; };

  mkAgentConfig =
    name: attr:
    let
      cfg = config.${namespace}.cli.llmAgents.${name};
      wrapper = pkgs.writeShellApplication {
        inherit name;
        text = ''
          exec ${pkgs.runtimeShell} ${./llm-agent-wrapper.sh} ${attr} "$@"
        '';
      };
    in
    mkIf cfg.enable { home.packages = [ wrapper ]; };

in
{
  options.${namespace}.cli.llmAgents = mapAttrs' mkAgentOption agents;

  config = mkMerge (
    lib.attrValues (
      mapAttrs' (name: attr: nameValuePair name (mkAgentConfig name attr)) agents
    )
  );
}
