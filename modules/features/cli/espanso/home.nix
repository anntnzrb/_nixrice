{ lib, config, ... }:
let
  cfg = config.liberion.cli.espanso;
in
{
  imports = [ ./matches/personal.nix ];

  options.liberion.cli.espanso = {
    extraMatchDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/espanso/match/local";
      description = ''
        Directory containing non-reproducible Espanso match files.
        Files in this directory are loaded alongside the Nix-managed matches.
      '';
    };
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
