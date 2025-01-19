{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.boot.bootloader.systemd-boot;
in
{
  options.${namespace}.boot.bootloader.systemd-boot = with lib.${namespace}; {
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
