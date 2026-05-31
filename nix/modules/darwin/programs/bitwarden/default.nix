{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.darwin.programs.mkOneMasAppProgram {
  inherit config namespace;
} "bitwarden" "Bitwarden" 1352778147
