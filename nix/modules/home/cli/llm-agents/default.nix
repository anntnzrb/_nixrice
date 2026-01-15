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

  # agents: name -> { type, ... }
  # type "npm": runs via `bun x <package>@<version>`
  # type "nix": runs via nix flake
  agents = {
    opencode = {
      type = "npm";
      package = "opencode-ai";
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
          VERSION="latest"
          while [ $# -gt 0 ]; do
            case "$1" in
              --version0)
                if [ $# -ge 2 ] && [ -n "''${2-}" ] && [ "''${2#-}" = "$2" ]; then
                  VERSION="$2"
                  shift 2
                  continue
                fi
                break
                ;;
              --version0=*)
                VERSION="''${1#*=}"
                shift
                continue
                ;;
              --) shift; break ;;
              *) break ;;
            esac
          done
          exec ${pkgs.bun}/bin/bun x "${spec.package}@$VERSION" "$@"
        '';
      }
    else
      pkgs.writeShellApplication {
        inherit name;
        text = ''exec ${pkgs.runtimeShell} ${./nix-agent-wrapper.sh} ${spec.attr} "$@"'';
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
    mkIf cfg.enable { home.packages = [ (mkWrapper name spec) ]; };

in
{
  options.${namespace}.cli.llmAgents = mapAttrs' (
    name: _: nameValuePair name { enable = mkOptDisabled'; }
  ) agents;

  config = mkMerge (mapAttrsToList mkAgentConfig agents);
}
