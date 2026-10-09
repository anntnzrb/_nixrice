{ config, lib, ... }:
let
  cfg = config.liberion.network.sshd;
  caKey = lib.liberion.varValue "shared/openssh-ca/id_ed25519.pub";
  certDomains = [
    config.clan.core.settings.domain
    lib.liberion.mdnsDomain
  ];
in
{
  config = {
    services.openssh = {
      enable = true;
      extraConfig = "AuthorizedKeysFile none";
    };

    programs.ssh.knownHosts.ssh-ca = lib.mkIf (caKey != null) {
      certAuthority = true;
      hostNames = map (domain: "*.${domain}") certDomains;
      publicKey = caKey;
    };

    launchd.daemons = lib.mkIf (cfg.port != 22) {
      "sshd-${toString cfg.port}" = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/sbin/sshd"
            "-D"
            "-p"
            (toString cfg.port)
          ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };
  };
}
