{
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # with useUserPackages, xdg portals of a hosted home are only found when the
  # system links their definitions (Home Manager asserts this)
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
