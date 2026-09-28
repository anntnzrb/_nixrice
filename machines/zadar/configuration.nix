{ pkgs, inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware
    networkmanager
    systemd-boot
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";
}
