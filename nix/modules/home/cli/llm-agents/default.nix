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
    cp ${./js-agent-wrapper.sh} "$out/${wrapperDir}/js-agent-wrapper.sh"
    cp ${./script-agent-wrapper.sh} "$out/${wrapperDir}/script-agent-wrapper.sh"
    cp ${./nix-agent-wrapper.sh} "$out/${wrapperDir}/nix-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/agent-wrapper-common.sh"
    chmod 755 "$out/${wrapperDir}/js-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/script-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/nix-agent-wrapper.sh"
  '';

  # agents: name -> { type, ... }
  # type "npm": runs via `bun x <package>@<version>`
  # type "nix": runs via nix flake
  # type "script": runs a local script via runner
  agents = {
    opencode = {
      type = "npm";
      package = "opencode-ai";
    };
    claude = {
      type = "script";
      runner = "${pkgs.bun}/bin/bun";
      script = "${config.home.homeDirectory}/.config/agents/tools/claude/bin/lib/claude.ts";
    };
    chutes = {
      type = "script";
      runner = "${pkgs.runtimeShell}";
      script = "${config.home.homeDirectory}/.config/agents/tools/chutes/bin/chutes";
    };
    pi = {
      type = "npm";
      package = "@mariozechner/pi-coding-agent";
    };
    gemini = {
      type = "npm";
      package = "@google/gemini-cli";
    };
    qwen = {
      type = "npm";
      package = "@qwen-code/qwen-code";
    };
    kilo = {
      type = "npm";
      package = "@kilocode/cli";
    };
    codex = {
      type = "npm";
      package = "@openai/codex";
    };
    crush = {
      type = "npm";
      package = "@charmland/crush";
    };
    goose = {
      type = "nix";
      attr = "goose-cli";
    };
    droid = {
      type = "nix";
      attr = "droid";
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
    if spec.type == "npm" then
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          exec ${pkgs.runtimeShell} ${wrappers}/${wrapperDir}/js-agent-wrapper.sh \
            ${pkgs.bun}/bin/bun ${spec.package} "$@"
        '';
      }
    else if spec.type == "script" then
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
      (mkIf (name == "codex") {
        home.sessionVariables.CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      })
      (mkIf (name == "pi") {
        home.sessionVariables.PI_CODING_AGENT_DIR = "${config.home.homeDirectory}/.config/pi/agent";
      })
    ]);

in
{
  options.${namespace}.cli.llmAgents = mapAttrs' (
    name: _: nameValuePair name { enable = mkOptDisabled'; }
  ) agents;

  config = mkMerge (mapAttrsToList mkAgentConfig agents);
}
