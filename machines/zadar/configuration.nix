{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    bash
    disko-xfs
    kernel-latest
    systemd-boot
  ];

  liberion.hardware.disko-xfs.device = "/dev/disk/by-id/ata-HGST_HTS721010A9E630_JR1000D30WN62E";

  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
}
