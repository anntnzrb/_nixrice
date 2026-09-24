{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' off;

  cfg = config.${namespace}.boot.bootloader.systemd-boot;
in
{
  options.${namespace}.boot.bootloader.systemd-boot = {
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
