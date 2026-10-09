{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.browsers.brave;
in
{
  options.liberion.desktop.browsers.brave.commandLineArgs = mkOpt' (listOf str) [
    "--no-default-browser-check"
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
  ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    programs.brave = {
      enable = true;
      inherit (cfg) commandLineArgs;
    };
  };
}
