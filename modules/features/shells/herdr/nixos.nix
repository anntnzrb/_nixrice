{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = lib.mkIf config.liberion.shells.herdr.desktop [
    pkgs.unstable.herdr-desktop
  ];
  users.users.${lib.liberion.identity.user}.linger = true;
}
