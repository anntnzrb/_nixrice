{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt mkOptDisabled';
  inherit (lib.${namespace}.fs) getModuleFiles;

  cfg = config.${namespace}.cli.espanso;
in
{
  imports = getModuleFiles { path = ./matches; };

  options.${namespace}.cli.espanso = {
    enable = mkOptDisabled';

    extraMatchDir =
      mkOpt lib.types.str "${config.xdg.configHome}/espanso/match/local"
        ''
          Directory containing non-reproducible Espanso match files.
          Files in this directory are loaded alongside the Nix-managed matches.
        '';
  };

  config = lib.mkIf cfg.enable {
    services.espanso = {
      inherit (cfg) enable;

      configs.default.extra_includes = [
        "${cfg.extraMatchDir}/**/*.yml"
        "${cfg.extraMatchDir}/**/*.yaml"
      ];
    };
  };
}
