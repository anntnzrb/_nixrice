{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.self.nixosModules.tailscale ];

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

  liberion.network.tailscale.expose.t3 = {
    port = 8443;
    target = "http://127.0.0.1:3773";
  };

  users.users.${lib.liberion.identity.user}.linger = true;
}
