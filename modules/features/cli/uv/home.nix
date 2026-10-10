{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.uv = {
    enable = true;
    package = pkgs.unstable.uv;
  };

  liberion.maintenance.tasks.uv.command = [
    (lib.getExe config.programs.uv.package)
    "cache"
    "prune"
  ];
}
