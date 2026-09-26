# tailscaled with tailscale ssh; the node takes the machine's hostname.
{ config, ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
      "--hostname=${config.networking.hostName}"
      "--accept-routes=true"
    ];
  };
}
