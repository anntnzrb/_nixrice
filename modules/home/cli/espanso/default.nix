{
  lib,
  config,
  namespace,
  pkgs,
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.espanso = {
        inherit (cfg) enable;

        configs.default.extra_includes = [
          "${cfg.extraMatchDir}/**/*.yml"
          "${cfg.extraMatchDir}/**/*.yaml"
        ];
      };
    })

    (lib.mkIf (!cfg.enable) {
      home.activation.cleanupEspanso =
        config.lib.dag.entryAfter [ "writeBoundary" ]
          ''
            label="com.federicoterzi.espanso"

            if command -v launchctl >/dev/null 2>&1; then
              uid="$(${pkgs.coreutils}/bin/id -u 2>/dev/null || true)"
              if [ -n "$uid" ]; then
                if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
                  run launchctl bootout "gui/$uid/$label" || :
                fi

                run launchctl disable "gui/$uid/$label" || :
              fi
            fi

            run ${pkgs.coreutils}/bin/rm -rf \
              "$HOME/Library/Caches/espanso" \
              "$HOME/Library/Preferences/com.federicoterzi.espanso.plist" \
              "$HOME/Library/LaunchAgents/com.federicoterzi.espanso.plist" \
              "$HOME/.config/espanso/match/base.yml" \
              "$HOME/.config/espanso/match/packages"

            run ${pkgs.coreutils}/bin/rmdir \
              "$HOME/.config/espanso/match/local" \
              "$HOME/.config/espanso/match" \
              "$HOME/.config/espanso" \
              2>/dev/null || :
          '';
    })
  ];
}
