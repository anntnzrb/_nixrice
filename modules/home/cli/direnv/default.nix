{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  exe = lib.getExe config.programs.direnv.package;

  cfg = config.liberion.cli.direnv;
in
{
  options.liberion.cli.direnv = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      inherit (cfg) enable;
      silent = true;
      nix-direnv = on;
    };

    home.shellAliases.dirrr = "${exe} allow && ${exe} reload";
  };
}
