{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.liberion.audio;
in {
  config = {
    boot = {
      consoleLogLevel = 3;

      tmp.cleanOnBoot = true;
    };

    boot.loader = {
      timeout = 10;

      efi.canTouchEfiVariables = true;
      grub.enable = false;

      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        consoleMode = "auto";
      };
    };
  };
}
