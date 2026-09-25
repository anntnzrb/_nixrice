# Hardware facts identical on solna, zadar and munich: the NIX-BOOT/NIX-ROOT
# label scheme and filesystem types. Per-host mount options and zram sizing
# stay in machines/<host>/hardware/default.nix.
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
