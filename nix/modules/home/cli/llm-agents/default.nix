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
    mapAttrsToList
    nameValuePair
    mkIf
    mkMerge
    ;

  wrapperDir = "lib/llm-agents";

  wrappers = pkgs.runCommand "llm-agent-wrappers" { } ''
    mkdir -p "$out/${wrapperDir}"
    cp ${./agent-wrapper-common.sh} "$out/${wrapperDir}/agent-wrapper-common.sh"
    cp ${./script-agent-wrapper.sh} "$out/${wrapperDir}/script-agent-wrapper.sh"
    cp ${./nix-agent-wrapper.sh} "$out/${wrapperDir}/nix-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/agent-wrapper-common.sh"
    chmod 755 "$out/${wrapperDir}/script-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/nix-agent-wrapper.sh"
  '';

  # agents: name -> { type, ... }
  # type "nix": runs via llm-agents.nix flake attr
  # type "script": runs a local script via runner
  agents = {
    opencode = {
      type = "nix";
      attr = "opencode";
    };
    claude = {
      type = "nix";
      attr = "claude-code";
    };
    chutes = {
      type = "script";
      runner = "${pkgs.runtimeShell}";
      script = "${config.home.homeDirectory}/.config/agents/tools/chutes/bin/chutes";
    };
    pi = {
      type = "nix";
      attr = "pi";
    };
    gemini = {
      type = "nix";
      attr = "gemini-cli";
    };
    qwen = {
      type = "nix";
      attr = "qwen-code";
    };
    kilo = {
      type = "nix";
      attr = "kilocode-cli";
    };
    codex = {
      type = "nix";
      attr = "codex";
    };
    crush = {
      type = "nix";
      attr = "crush";
    };
    goose = {
      type = "nix";
      attr = "goose-cli";
    };
    droid = {
      type = "nix";
      attr = "droid";
    };
    omp = {
      type = "nix";
      attr = "omp";
    };
  };

  /**
    Create a wrapper derivation for an agent.

    # Type

    ```
    mkWrapper :: String -> AttrSet -> Derivation
    ```
  */
  mkWrapper =
    name: spec:
    if spec.type == "script" then
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          exec ${pkgs.runtimeShell} ${wrappers}/${wrapperDir}/script-agent-wrapper.sh \
            ${spec.runner} ${spec.script} "$@"
        '';
      }
    else
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          exec ${pkgs.runtimeShell} ${wrappers}/${wrapperDir}/nix-agent-wrapper.sh \
            ${spec.attr} "$@"
        '';
      };

  /**
    Create module configuration for an agent.

    # Type

    ```
    mkAgentConfig :: String -> AttrSet -> AttrSet
    ```
  */
  mkAgentConfig =
    name: spec:
    let
      cfg = config.${namespace}.cli.llmAgents.${name};
    in
    mkIf cfg.enable (mkMerge [
      { home.packages = [ (mkWrapper name spec) ]; }
    ]);
in
{
  options.${namespace}.cli.llmAgents = mapAttrs' (
    name: _: nameValuePair name { enable = mkOptDisabled'; }
  ) agents;

  config = mkMerge (mapAttrsToList mkAgentConfig agents);
}
