{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cfg = config.liberion.cli.git;
in
{
  config = mkIf cfg.enable {
    programs.gh = mkIf cfg.gh.enable { inherit (cfg.gh) enable; };
  };
}
