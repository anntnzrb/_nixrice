_:

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
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
            # increase xfs in-memory log buffer size and disable access time updates for build server workload
            mountOptions = [
              "noatime"
              "nodiratime"
              "logbufs=8"
              "logbsize=256k"
            ];
          };
        };
      };
    };
  };
}
