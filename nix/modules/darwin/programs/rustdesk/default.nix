{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.darwin.programs.mkOneCaskProgram {
  inherit config namespace;
} "rustdesk" "rustdesk"
