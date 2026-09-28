{ lib, pkgs, ... }:
let
  userName = lib.liberion.identity.user;
in
{
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
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
