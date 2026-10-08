{ lib, pkgs, ... }: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-core
      dbus
      expat
      fontconfig
      freetype
      glib
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      systemd
    ];
  };

  users.users.${lib.liberion.identity.user}.linger = true;
}
