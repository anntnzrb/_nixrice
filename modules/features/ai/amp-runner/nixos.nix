{ lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    ffmpeg
    labwc
    wlr-randr
  ];

  users.users.${lib.liberion.identity.user}.linger = true;
}
