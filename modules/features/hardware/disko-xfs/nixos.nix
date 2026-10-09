{ config, lib, ... }:
let
  cfg = config.liberion.hardware.disko-xfs;
in
{
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
