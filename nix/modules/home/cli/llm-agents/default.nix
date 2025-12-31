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

  /**
    Create an option for an LLM agent.

    # Example

    ```nix
    mkAgentOption "opencode" null
    =>
    { name = "opencode"; value = { enable = <option>; }; }
    ```

    # Type

    ```
    mkAgentOption :: String -> Any -> NamedValue
    ```

    # Arguments

    name
    : The agent name identifier

    The second argument is ignored (used for mapAttrs application).
  */
  mkAgentOption = name: _: nameValuePair name { enable = mkOptDisabled'; };

  /**
    Create configuration for an LLM agent wrapper.

    # Example

    ```nix
    mkAgentConfig "opencode" "opencode"
    =>
    { enable = true; home.packages = [ <wrapper derivation> ]; }
    ```

    # Type

    ```
    mkAgentConfig :: String -> String -> AttrSet
    ```

    # Arguments

    name
    : The agent name identifier

    attr
    : The flake reference for the agent package
  */
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
