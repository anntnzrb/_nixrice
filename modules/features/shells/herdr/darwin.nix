{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.liberion.shells.herdr-core;
in
{
  imports = [ inputs.self.darwinModules.homebrew ];

  options.liberion.shells.herdr-core.desktop = lib.liberion.module.mkOptDisabled';

  config = {
    liberion.darwin.homebrew.apps = lib.mkIf cfg.desktop [ "herdr-app" ];
    launchd.user.envVariables.SHELL = lib.mkIf cfg.desktop (
      "/run/current-system/sw"
      + config.users.users.${lib.liberion.identity.user}.shell.shellPath
    );
  };
}
