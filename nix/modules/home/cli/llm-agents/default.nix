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
  bunPkg = pkgs.bun;
  bunExe = "${bunPkg}/bin/bun";
  shell = pkgs.runtimeShell;
  syncScript = "${config.home.homeDirectory}/.config/agents/sync/src/cli.ts";
  coreRuntimeInputs = [
    bunPkg
    pkgs.coreutils
  ];

  wrappers = pkgs.runCommand "llm-agent-wrappers" { } ''
    mkdir -p "$out/${wrapperDir}"
    cp ${./agent-wrapper-common.sh} "$out/${wrapperDir}/agent-wrapper-common.sh"
    cp ${./npm-agent-wrapper.sh} "$out/${wrapperDir}/npm-agent-wrapper.sh"
    cp ${./script-agent-wrapper.sh} "$out/${wrapperDir}/script-agent-wrapper.sh"
    cp ${./nix-agent-wrapper.sh} "$out/${wrapperDir}/nix-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/agent-wrapper-common.sh"
    chmod 755 "$out/${wrapperDir}/npm-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/script-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/nix-agent-wrapper.sh"
  '';

  # agents: name -> { type, ... }
  # type "npm": runs via `bun x <package>@<version>`
  # type "nix": runs via llm-agents.nix flake attr
  # type "script": runs a local script via runner
  agents = {
    opencode = {
      type = "npm";
      package = "opencode-ai";
    };
    pi = {
      type = "npm";
      package = "@earendil-works/pi-coding-agent";
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
    omp = {
      type = "npm";
      package = "@oh-my-pi/pi-coding-agent@latest";
    };
  };

  mkShellWrapper =
    name: runtimeInputs: text:
    pkgs.writeShellApplication { inherit name runtimeInputs text; };

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
      mkShellWrapper name [ bunPkg pkgs.nodejs ] ''
        exec ${shell} ${wrappers}/${wrapperDir}/npm-agent-wrapper.sh \
          ${bunExe} ${syncScript} ${spec.package} "$@"
      ''
    else if spec.type == "script" then
      mkShellWrapper name coreRuntimeInputs ''
        exec ${shell} ${wrappers}/${wrapperDir}/script-agent-wrapper.sh \
          ${bunExe} ${syncScript} ${spec.runner} ${spec.script} "$@"
      ''
    else
      mkShellWrapper name coreRuntimeInputs ''
        exec ${shell} ${wrappers}/${wrapperDir}/nix-agent-wrapper.sh \
          ${bunExe} ${syncScript} ${spec.attr} ${name} "$@"
      '';

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
      cfg = config.${namespace}.cli."llm-agents".${name};
    in
    mkIf cfg.enable (mkMerge [ { home.packages = [ (mkWrapper name spec) ]; } ]);
in
{
  options.${namespace}.cli."llm-agents" = mapAttrs' (
    name: _: nameValuePair name { enable = mkOptDisabled'; }
  ) agents;

  config = mkMerge (mapAttrsToList mkAgentConfig agents);
}
