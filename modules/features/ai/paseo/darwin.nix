{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.liberion.ai.paseo;
in
{
  imports = [ inputs.self.darwinModules.homebrew ];

  options.liberion.ai.paseo.desktop = lib.liberion.module.mkOptDisabled';

  config.liberion.darwin.homebrew.apps = lib.mkIf cfg.desktop [ "paseo" ];
}
