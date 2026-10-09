{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  home = config.home-manager.users.${lib.liberion.identity.user};
  shared = import ./settings.nix { inherit lib; };
  policies = import ./policies.nix {
    inherit lib inputs;
    cfg = home.liberion.desktop.browsers.firefox;
    policies = home.programs.firefox.policies;
    extensions =
      shared.extensions
        inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
  };
in
{
  imports = [
    (lib.liberion.darwin.homebrewApps [ "firefox" ])
    (lib.liberion.darwin.managedPreferences {
      domain = "org.mozilla.firefox";
      settings = policies;
    })
  ];
}
