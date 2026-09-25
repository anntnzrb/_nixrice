{ config, lib, ... }:
let

  exe = lib.getExe config.programs.direnv.package;
in
{
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  home.shellAliases.dirrr = "${exe} allow && ${exe} reload";
}
