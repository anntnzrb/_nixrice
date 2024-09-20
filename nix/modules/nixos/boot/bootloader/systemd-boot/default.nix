{ config, lib, ... }:
let
  cfg = config.liberion.boot.bootloader.systemd-boot;
in
{
  options.liberion.boot.bootloader.systemd-boot = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      grub.enable = false;

      systemd-boot = {
        enable = true;

        configurationLimit = 20;
        consoleMode = "auto";
      };
    };
  };
}
