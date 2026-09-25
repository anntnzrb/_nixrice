{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' off;

  cfg = config.liberion.boot.bootloader.systemd-boot;
in
{
  options.liberion.boot.bootloader.systemd-boot = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      grub = off;

      systemd-boot = {
        inherit (cfg) enable;

        configurationLimit = 20;
        consoleMode = "auto";
      };
    };
  };
}
