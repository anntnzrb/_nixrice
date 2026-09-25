import ../../../toggle.nix "cli.direnv" (
  { config, lib, ... }:
  let
    inherit (lib.liberion.module) on;

    exe = lib.getExe config.programs.direnv.package;
  in
  {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv = on;
    };

    home.shellAliases.dirrr = "${exe} allow && ${exe} reload";
  }
)
