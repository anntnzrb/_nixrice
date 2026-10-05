{
  inputs,
  lib,
  config,
  ...
}:
let
  proxy = config.liberion.ai.cliproxyapi;
in
{
  imports = with inputs.self.nixosModules; [
    ./disk.nix
    bash
    essentials
    networkmanager
    systemd-boot
    tailscale
    cliproxyapi
  ];

  users.users.${lib.liberion.identity.user}.linger = true;

  liberion.network.tailscale.expose = {
    proxy-private = {
      port = 9443;
      target = "http://${proxy.settings.host}:${toString proxy.settings.port}";
    };
    proxy-public = {
      port = 443;
      target = "http://127.0.0.1:${toString proxy.publicAuthPort}";
      funnel = true;
    };
  };
  liberion.ai.cliproxyapi.publicAuth = true;

  hardware.facter.detected = {
    bluetooth.enable = false;
    dhcp.enable = false;
  };

  networking.useNetworkd = false;
  systemd.network.enable = false;

  services.fstrim.enable = true;

  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };
}
