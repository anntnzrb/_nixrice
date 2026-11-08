{ lib, pkgs, ... }: {
  services.envfs = {
    enable = true;
    extraFallbackPathCommands = "ln -sf ${lib.getExe pkgs.bashInteractive} $out/bash";
  };
}
