{
  lib,
  pkgs,
  self,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [
    self.nixosModules.default
    ./hardware
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  ${namespace} = {
    user = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  home-manager.users.annt.imports = [ ./home.nix ];

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
