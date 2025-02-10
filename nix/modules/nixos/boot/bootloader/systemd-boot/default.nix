{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.boot.bootloader.systemd-boot;
in
{
  options.${namespace}.boot.bootloader.systemd-boot = {
    enable = mkOptDisabled';
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
