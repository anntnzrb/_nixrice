{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.network.ssh;
in
{
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/network/ssh/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    services.openssh = { inherit (cfg) enable; };

    # macOS sshd is socket-activated from Apple's stock ssh.plist, whose
    # socket is fixed at port 22, so a `Port` directive in sshd_config has no
    # effect and nix-darwin's services.openssh has no port option. Run a
    # second foreground sshd for cfg.port instead.
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
