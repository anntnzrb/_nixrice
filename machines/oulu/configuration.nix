{
  inputs,
  lib,
  pkgs,
  ...
}:
{
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

  environment.systemPackages = [ (pkgs.callPackage ./waymote.nix { }) ];

  nix.settings = {
    max-jobs = 6;
    cores = 4;
  };

  systemd.oomd.enableUserSlices = true;
}
