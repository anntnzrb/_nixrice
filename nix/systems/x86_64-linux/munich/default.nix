{lib, ...}: let
  inherit (lib.liberion) on;
in {
  imports = [
    ./hardware
  ];

  system.stateVersion = "23.05";

  time.timeZone = "America/Guayaquil";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "caps:none";
  };

  liberion = {
    user.shell = "fish";

    audio = on;
    virtualisation.docker = on;
    network.vpn.mullvad = on;

    desktop.xserver = on;
  };
}
