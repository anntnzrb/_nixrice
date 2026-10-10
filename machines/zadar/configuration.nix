{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    amp-runner
    bash
    disko-xfs
    essentials
    kernel-latest
    podman
    systemd-boot
    t3
  ];

  environment.localBinInPath = true;
  programs.nix-ld.enable = true;

  home-manager.users.${lib.liberion.identity.user}.liberion.ai.amp-runner.desktop =
    false;

  liberion.hardware.disko-xfs.device = "/dev/disk/by-id/ata-HGST_HTS721010A9E630_JR1000D30WN62E";

  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";

  systemd.oomd.enableUserSlices = true;
}
