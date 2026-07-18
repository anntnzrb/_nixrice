/**
  CLI wrapper for the Chutes LLM API. Provides a shell script to interact with LLMs via https://llm.chutes.ai.

  # Type

  ```
  package :: Derivation
  ```
*/
{ pkgs, ... }:
let
  exe = "chutes";
in
pkgs.writeShellApplication {
  name = exe;

  runtimeInputs = with pkgs; [
    curl
    jq
  ];

  text = builtins.readFile ./src/${exe}.sh;
}
