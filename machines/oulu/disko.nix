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
