import ../../../toggle.nix "virtualisation.podman" (
  { pkgs, config, ... }:
  let
    userName = config.liberion.user.name;
  in
  {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        # docker cli alias + compatibility socket
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
    };

    # socket access for the primary user through the podman group
    users.groups.podman = { };
    users.users.${userName}.extraGroups = [ "podman" ];
    systemd.sockets.podman.socketConfig = {
      SocketGroup = "podman";
      SocketMode = "0660";
    };

    environment = {
      systemPackages = with pkgs; [
        docker-compose
        podman-tui
      ];
      sessionVariables.DOCKER_HOST = "unix:///var/run/docker.sock";
    };
  }
)
