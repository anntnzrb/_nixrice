{ config, lib, ... }:
let
  inherit (config.liberion.darwin.owned) shell;
in
{
  imports = [ (lib.liberion.darwin.homebrewApps [ "herdr-app" ]) ];

  launchd.user.envVariables.SHELL = lib.mkIf (shell != null) shell;
}
