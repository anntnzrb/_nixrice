{ lib }: rec {
  managedPreferences =
    { domain, settings }:
    { pkgs, ... }:
    let
      target = "/Library/Managed Preferences/${domain}.plist";
      plist = pkgs.writeText "${domain}.plist" (
        lib.generators.toPlist { escape = true; } settings
      );
    in
    {
      liberion.darwin.owned.files.${target}.restart = [ "cfprefsd" ];
      system.activationScripts.postActivation.text = lib.mkAfter ''
        managed_policy_target=${lib.escapeShellArg target}
        mkdir -p "/Library/Managed Preferences"
        if ! cmp -s ${plist} "$managed_policy_target"; then
          install -m 0644 -o root -g wheel ${plist} "$managed_policy_target"
          killall cfprefsd >/dev/null 2>&1 || :
        fi
      '';
    };

  homebrewApps = apps: { inputs, ... }: {
    imports = [ inputs.self.darwinModules.homebrew ];
    liberion.darwin.homebrew.apps = apps;
  };

  wmHandoff = { pkgs, user }: import ./wm-handoff.nix { inherit lib pkgs user; };

  asUser =
    user:
    ''launchctl asuser "$(id -u -- ${lib.escapeShellArg user})" sudo --user=${lib.escapeShellArg user} --'';

  activateSettings = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";

  writeDefault =
    {
      domain,
      key,
      value,
      currentHost ? false,
    }:
    lib.concatStringsSep " " (
      [ "defaults" ]
      ++ lib.optional currentHost "-currentHost"
      ++ [
        "write"
        (lib.escapeShellArg domain)
        (lib.escapeShellArg key)
        (lib.escapeShellArg (lib.generators.toPlist { escape = true; } value))
      ]
    );

  writeDefaults =
    user:
    {
      domain,
      settings,
      currentHost ? false,
    }:
    lib.mapAttrsToList (
      key: value:
      "${asUser user} ${
        writeDefault {
          inherit
            domain
            key
            value
            currentHost
            ;
        }
      }"
    ) (lib.filterAttrs (_: v: v != null) settings);

  aquaAgent =
    managedBy: agent:
    lib.recursiveUpdate {
      inherit managedBy;
      serviceConfig = {
        RunAtLoad = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
      };
    } agent;

  openAtLogin =
    app: managedBy:
    aquaAgent managedBy {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "/Applications/${app}.app"
        ];
        KeepAlive = false;
      };
    };
}
