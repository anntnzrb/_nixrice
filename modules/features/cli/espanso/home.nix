{ config, lib, ... }:
let
  cfg = config.liberion.cli.espanso;
in
{
  imports = [ ./matches/personal.nix ];

  options.liberion.cli.espanso = {
    extraMatchDir = lib.liberion.module.mkOpt' lib.types.str "${config.xdg.configHome}/espanso/match/local";
  };

  config.services.espanso = {
    enable = true;

    configs.default.extra_includes = [
      "${cfg.extraMatchDir}/**/*.yml"
      "${cfg.extraMatchDir}/**/*.yaml"
    ];

    matches.default.matches = import ./matches/dictionary.nix;
  };
}
