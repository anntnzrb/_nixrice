# Filesystems by label: btrfs root (NIX-ROOT) and vfat /boot (NIX-BOOT). Mount options and swap stay with the machine.
{
  fileSystems =
    let
      bootLabel = "NIX-BOOT";
      rootLabel = "NIX-ROOT";
    in
    {
      "/" = {
        device = "/dev/disk/by-label/${rootLabel}";
        label = rootLabel;
        fsType = "btrfs";
      };

      "/boot" = {
        device = "/dev/disk/by-label/${bootLabel}";
        label = bootLabel;
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };
    };
}
