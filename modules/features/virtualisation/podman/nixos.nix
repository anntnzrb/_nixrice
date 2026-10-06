{ pkgs, ... }: {
  # Rootless only: each user's containers run in their own namespace, and the
  # Docker-compatible API is that user's socket. No group grants the rootful
  # socket, which would be root without sudo.
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      docker-compose
      podman-tui
    ];
    # Docker clients talk to the login user's rootless API socket.
    extraInit = ''
      if [ -n "''${XDG_RUNTIME_DIR-}" ]; then
        export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
      fi
    '';
  };
}
