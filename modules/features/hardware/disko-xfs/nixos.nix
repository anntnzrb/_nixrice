# Whole-disk layout: 1 GiB EFI system partition + XFS root with reflinks.
# Wipes the disk on install.
{ lib, config, ... }:
let
  cfg = config.liberion.hardware.disko-xfs;
in
{
  # the whole disk to partition; prefer a stable /dev/disk/by-id path
  options.liberion.hardware.disko-xfs.device =
    lib.liberion.module.mkOpt' lib.types.str "/dev/nvme0n1";

  config.disko.devices.disk.main = {
    type = "disk";
    inherit (cfg) device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          end = "1024M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            extraArgs = [
              "-n"
              "BOOT"
            ];
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          name = "root";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
            extraArgs = [
              "-L"
              "nixos"
              "-m"
              "reflink=1"
              "-m"
              "crc=1"
              "-d"
              "agcount=16"
            ];
            # larger xfs log buffers and no access time updates for build/agent workload
            # (noatime implies nodiratime; logbufs=8 is the default)
            mountOptions = [
              "noatime"
              "logbsize=256k"
            ];
          };
        };
      };
    };
  };
}
