{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.ai.cliproxyapi;
  yamlFormat = pkgs.formats.yaml { };

  baseConfigFile = yamlFormat.generate "cliproxyapi-base.yaml" cfg.settings;

  python = pkgs.python313.withPackages (p: [ p.pyyaml ]);

  account = "cliproxyapi";
  paths = {
    state = "/var/lib/${account}";
    runtime = "/run/${account}";
  };
  stateDir = paths.state;
  runtimeDir = paths.runtime;
  policy = {
    restartDelay = 3;
    gracefulStop = 90;
    authStop = 30;
    preparationTimeout = "10min";
    restartWindow = 300;
    restartBurst = 5;
    updateCalendar = "*-*-* 04:00:00";
    updateJitter = "15m";
  };
  runtimeConfigFile = "${runtimeDir}/config.yaml";

  installerScript = pkgs.writeShellScript "cliproxyapi-install" ''
    set -eu
    if [ ! -x "${stateDir}/releases/current/cli-proxy-api" ]; then
      exec ${python}/bin/python ${./release.py} install \
        --state "${stateDir}/releases" \
        --version "latest"
    fi
  '';

  configureScript = pkgs.writeShellScript "cliproxyapi-configure" ''
    set -eu
    secretsFile="''${CREDENTIALS_DIRECTORY:-}/secrets.json"
    if [ ! -f "$secretsFile" ]; then
      secretsFile="${cfg.credentialsFile}"
    fi
    exec ${python}/bin/python ${./configure.py} \
      --settings "${baseConfigFile}" \
      --secrets "$secretsFile" \
      --out "${runtimeConfigFile}"
  '';
  updateScript = pkgs.writeShellScript "cliproxyapi-update" ''
    set -eu
    before=$(${pkgs.coreutils}/bin/readlink "${stateDir}/releases/current" || true)
    ${pkgs.util-linux}/bin/runuser -u ${account} -- ${python}/bin/python ${./release.py} install --state "${stateDir}/releases" --version latest
    after=$(${pkgs.coreutils}/bin/readlink "${stateDir}/releases/current")
    if [ "$before" != "$after" ]; then
      ${pkgs.systemd}/bin/systemctl try-restart cliproxyapi.service
    fi
  '';
in
{
  options.liberion.ai.cliproxyapi = {
    credentialsFile = lib.liberion.module.mkOpt' lib.types.path "${paths.state}/secrets.json";
    publicAuth = lib.liberion.module.mkOptDisabled';
    publicAuthPort = lib.liberion.module.mkOpt' lib.types.port 8318;
    settings = lib.liberion.module.mkOpt' yamlFormat.type (
      import ./settings.nix { inherit paths; }
    );
  };

  config = {
    users.users.cliproxyapi = {
      isSystemUser = true;
      group = account;
      description = "CLIProxyAPI service daemon user";
      home = stateDir;
    };
    users.groups.cliproxyapi = { };

    systemd = {
      services = {
        cliproxyapi-install = {
          description = "Install offline baseline CLIProxyAPI release if missing";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = account;
            Group = account;
            StateDirectory = account;
            ExecStart = "${installerScript}";
            TimeoutStartSec = policy.preparationTimeout;
          };
        };

        cliproxyapi = {
          description = "CLIProxyAPI backend service";
          after = [
            "network-online.target"
            "cliproxyapi-install.service"
          ];
          wants = [
            "network-online.target"
            "cliproxyapi-install.service"
          ];
          wantedBy = [ "multi-user.target" ];
          unitConfig = {
            StartLimitIntervalSec = policy.restartWindow;
            StartLimitBurst = policy.restartBurst;
            ConditionPathExists = cfg.credentialsFile;
          };
          serviceConfig = {
            User = account;
            Group = account;
            StateDirectory = account;
            StateDirectoryMode = "0700";
            UMask = "0077";
            RuntimeDirectory = account;
            RuntimeDirectoryMode = "0700";
            LoadCredential = "secrets.json:${cfg.credentialsFile}";
            ExecStartPre = [
              "${installerScript}"
              "${configureScript}"
            ];
            ExecStart = "${python}/bin/python ${./release.py} run --state ${stateDir}/releases --config ${runtimeConfigFile}";
            Restart = "always";
            RestartSec = policy.restartDelay;
            TimeoutStopSec = policy.gracefulStop;
            KillMode = "mixed";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [
              stateDir
              runtimeDir
            ];
          };
        };

        cliproxyapi-update = {
          description = "Check and update CLIProxyAPI release daily";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${updateScript}";
            TimeoutStartSec = policy.preparationTimeout;
            Nice = 19;
          };
        };

        cliproxy-auth-gateway = lib.mkIf cfg.publicAuth {
          description = "CLIProxyAPI public auth gateway";
          after = [
            "network-online.target"
            "cliproxyapi.service"
          ];
          wants = [
            "network-online.target"
            "cliproxyapi.service"
          ];
          wantedBy = [ "multi-user.target" ];
          unitConfig = {
            ConditionPathExists = cfg.credentialsFile;
          };
          serviceConfig = {
            User = account;
            Group = account;
            LoadCredential = "secrets.json:${cfg.credentialsFile}";
            Environment = [
              "CLIPROXY_UPSTREAM=http://${cfg.settings.host}:${toString cfg.settings.port}"
              "GATEWAY_PORT=${toString cfg.publicAuthPort}"
            ];
            ExecStart = "${python}/bin/python ${./auth-gateway.py}";
            Restart = "always";
            RestartSec = policy.restartDelay;
            TimeoutStopSec = policy.authStop;
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
          };
        };
      };
      timers.cliproxyapi-update = {
        description = "Daily check for CLIProxyAPI release updates";
        timerConfig = {
          OnCalendar = policy.updateCalendar;
          RandomizedDelaySec = policy.updateJitter;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };
    };
  };
}
