{
  pkgs,
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace};
in
{
  config = {
    system.stateVersion = "22.05";

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

    environment.systemPackages = with pkgs; [
      # tools
      git
      man-pages-posix

      # archiving
      atool
      p7zip
      rar
      unzip
      zip

      # misc
      kmon
    ];
  };
}
