{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.cli.git;
in
{
  config = mkIf cfg.enable {
    programs.gh = mkIf cfg.gh.enable { inherit (cfg.gh) enable; };
  };
}
