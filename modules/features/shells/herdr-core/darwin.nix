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

  config.liberion.darwin.homebrew.apps = lib.mkIf cfg.desktop [ "herdr-app" ];
}
