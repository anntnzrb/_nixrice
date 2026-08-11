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
  npmRuntimeInputs = [
    bunPkg
    pkgs.nodejs
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.flock
  ];

  wrappers = pkgs.runCommand "llm-agent-wrappers" { } ''
    mkdir -p "$out/${wrapperDir}"
    cp ${./agent-wrapper-common.sh} "$out/${wrapperDir}/agent-wrapper-common.sh"
    cp ${./npm-agent-wrapper.sh} "$out/${wrapperDir}/npm-agent-wrapper.sh"
    chmod 755 "$out/${wrapperDir}/agent-wrapper-common.sh"
    chmod 755 "$out/${wrapperDir}/npm-agent-wrapper.sh"
  '';

  # agents: name -> { package, bin }
  # package is resolved from npm's latest dist-tag and bin selects its executable.
  agents = {
    opencode = {
      package = "opencode-ai";
      bin = "opencode";
    };
    pi = {
      package = "@earendil-works/pi-coding-agent";
      bin = "pi";
    };
    codex = {
      package = "@openai/codex";
      bin = "codex";
    };
    omp = {
      package = "@oh-my-pi/pi-coding-agent";
      bin = "omp";
    };
  };

  mkShellWrapper =
    name: runtimeInputs: text:
    pkgs.writeShellApplication { inherit name runtimeInputs text; };

  /**
    Create an npm launcher wrapper for an agent package and binary.

    # Type

    ```
    mkWrapper :: String -> { package, bin } -> Derivation
    ```
  */
  mkWrapper =
    name: agent:
    mkShellWrapper name npmRuntimeInputs ''
      exec ${lib.escapeShellArg shell} \
        ${lib.escapeShellArg "${wrappers}/${wrapperDir}/npm-agent-wrapper.sh"} \
        ${lib.escapeShellArg bunExe} \
        ${lib.escapeShellArg syncScript} \
        ${lib.escapeShellArg name} \
        ${lib.escapeShellArg agent.package} \
        ${lib.escapeShellArg agent.bin} \
        "$@"
    '';

  /**
    Create module configuration for an agent.

    # Type

    ```
    mkAgentConfig :: String -> { package, bin } -> AttrSet
    ```
  */
  mkAgentConfig =
    name: agent:
    let
      cfg = config.${namespace}.cli."llm-agents".${name};
    in
    mkIf cfg.enable (mkMerge [ { home.packages = [ (mkWrapper name agent) ]; } ]);
in
{
  options.${namespace}.cli."llm-agents" = mapAttrs' (
    name: _: nameValuePair name { enable = mkOptDisabled'; }
  ) agents;

  config = mkMerge (mapAttrsToList mkAgentConfig agents);
}
