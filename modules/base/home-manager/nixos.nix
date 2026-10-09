{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  environment.pathsToLink =
    lib.mkIf
      (lib.any (home: home.xdg.portal.enable) (
        lib.attrValues config.home-manager.users
      ))
      [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];
}
