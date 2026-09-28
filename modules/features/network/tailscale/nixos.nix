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
