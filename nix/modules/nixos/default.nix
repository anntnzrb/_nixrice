{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.nixos;
in
{
  options.${namespace}.nixos = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = "America/Guayaquil";

    i18n = rec {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = defaultLocale;
        LC_IDENTIFICATION = defaultLocale;
        LC_MEASUREMENT = defaultLocale;
        LC_MONETARY = defaultLocale;
        LC_NAME = defaultLocale;
        LC_NUMERIC = defaultLocale;
        LC_PAPER = defaultLocale;
        LC_TELEPHONE = defaultLocale;
        LC_TIME = defaultLocale;
      };
    };

    system.stateVersion = "22.05";
  };
}
