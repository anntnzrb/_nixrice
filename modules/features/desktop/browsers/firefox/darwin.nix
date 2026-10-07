{ lib, config, ... }:
let
  home = config.home-manager.users.${lib.liberion.identity.user};
  domain = home.programs.firefox.darwinDefaultsId;
in
{
  imports = [ (lib.liberion.darwin.homebrewApps [ "firefox" ]) ];

  liberion.darwin.owned.defaults = lib.optionals (domain != null) (
    map (key: { inherit domain key; }) (
      lib.attrNames (home.targets.darwin.defaults.${domain} or { })
    )
  );
}
