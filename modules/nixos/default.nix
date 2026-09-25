{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptEnabled';

  cfg = config.liberion.nixos;
in
{
  options.liberion.nixos = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = "America/Guayaquil";

    i18n =
      let
        defaultLocale = "en_US.UTF-8";
      in
      {
        inherit defaultLocale;
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
