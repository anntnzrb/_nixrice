{
  lib,
  config,
  pkgs,
  ...
}:
{
  # One-shot cleanup of leftover Espanso state on homes without Espanso.
  config = lib.mkIf (!config.services.espanso.enable) {
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
  };
}
