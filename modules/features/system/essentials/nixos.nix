{ lib, pkgs, ... }: {
  services.envfs = {
    enable = true;
    extraFallbackPathCommands = "ln -s ${lib.getExe pkgs.bashInteractive} $out/bash";
  };
}
