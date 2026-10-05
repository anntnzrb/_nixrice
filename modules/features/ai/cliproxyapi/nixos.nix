{ inputs, pkgs, ... }:
let
  account = "cliproxyapi";
  stateDir = "/var/lib/${account}";
  releases = "${stateDir}/releases";
  secretsFile = "${stateDir}/secrets.json";
  modelsCache = "${stateDir}/models.json";
  runtimeConfig = "/run/${account}/config.yaml";
  authPort = 8318;

  settings = import ./settings.nix { inherit stateDir; };
  baseConfig = (pkgs.formats.yaml { }).generate "cliproxyapi-base.yaml" settings;
  python = pkgs.python313.withPackages (p: [ p.pyyaml ]);

  install = "${python}/bin/python ${./release.py} install --state ${releases} --version latest";
  configure = "${python}/bin/python ${./configure.py} --settings ${baseConfig} --models-cache ${modelsCache}";

  installIfMissing = pkgs.writeShellScript "cliproxyapi-install" ''
    [ -x "${releases}/current/cli-proxy-api" ] || exec ${install}
  '';

  update = pkgs.writeShellScript "cliproxyapi-update" ''
    set -eu
    state() {
      ${pkgs.coreutils}/bin/readlink "${releases}/current" || true
      ${pkgs.coreutils}/bin/cat "${modelsCache}" 2>/dev/null || true
    }
    before=$(state)
    ${pkgs.util-linux}/bin/runuser -u ${account} -- ${install}
    ${pkgs.util-linux}/bin/runuser -u ${account} -- ${configure} --secrets ${secretsFile}
    if [ "$before" != "$(state)" ]; then
      ${pkgs.systemd}/bin/systemctl try-restart cliproxyapi.service
    fi
  '';
in
{
  imports = [ inputs.self.nixosModules.tailscale ];

  programs.nix-ld.enable = true;

  users.users.${account} = {
    isSystemUser = true;
    group = account;
    home = stateDir;
  };
  users.groups.${account} = { };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ settings.port ];

  liberion.network.tailscale.expose.cliproxyapi-amp = {
    port = 443;
    target = "http://127.0.0.1:${toString authPort}";
    funnel = true;
  };

  systemd = {
    services = {
      cliproxyapi = {
        description = "CLIProxyAPI";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = secretsFile;
        serviceConfig = {
          User = account;
          Group = account;
          StateDirectory = [
            account
            "${account}/auth"
          ];
          StateDirectoryMode = "0700";
          RuntimeDirectory = account;
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
          LoadCredential = "secrets.json:${secretsFile}";
          ExecStartPre = [
            installIfMissing
            "${configure} --secrets %d/secrets.json --out ${runtimeConfig}"
          ];
          ExecStart = "${python}/bin/python ${./release.py} run --state ${releases} --config ${runtimeConfig}";
          TimeoutStartSec = "10min";
          Restart = "always";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ stateDir ];
        };
      };

      cliproxyapi-update = {
        description = "Update CLIProxyAPI release and model catalog";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = update;
          TimeoutStartSec = "10min";
          Nice = 19;
        };
      };

      cliproxy-auth-gateway = {
        description = "CLIProxyAPI token gate for Amp";
        after = [ "cliproxyapi.service" ];
        wants = [ "cliproxyapi.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathExists = secretsFile;
        serviceConfig = {
          User = account;
          Group = account;
          LoadCredential = "secrets.json:${secretsFile}";
          Environment = "CLIPROXY_UPSTREAM=http://127.0.0.1:${toString settings.port}";
          ExecStart = "${python}/bin/python ${./auth-gateway.py}";
          Restart = "always";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
    };

    timers.cliproxyapi-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "04:00";
        Persistent = true;
      };
    };
  };
}
