# Mainline kernel: newest drivers and scheduler (e.g. hybrid P/E cores).
{ pkgs, ... }: { boot.kernelPackages = pkgs.linuxPackages_latest; }
