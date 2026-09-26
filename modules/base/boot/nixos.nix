# Boot baseline for every NixOS host; the loader lives in a boot feature
# (systemd-boot, grub) or wsl.
{ boot.tmp.cleanOnBoot = true; }
