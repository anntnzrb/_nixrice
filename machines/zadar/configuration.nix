{ lib, pkgs, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ ./hardware ];

  nixpkgs.hostPlatform = "x86_64-linux";

  liberion = {
    user = on;
    profiles.headless = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  home-manager.users.annt.imports = [ ./home.nix ];

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";
}
