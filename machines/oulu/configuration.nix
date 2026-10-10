{ inputs, pkgs, ... }: {
  imports = with inputs.self.nixosModules; [
    bash
    disko-xfs
    kernel-latest
    systemd-boot
  ];

  liberion.hardware.disko-xfs.device = "/dev/disk/by-id/nvme-SKHynix_HFS001TEJ4X112N_4YD6N024714806Q05";

  environment.systemPackages = [ (pkgs.callPackage ./waymote.nix { }) ];

  nix.settings = {
    max-jobs = 6;
    cores = 4;
  };
}
