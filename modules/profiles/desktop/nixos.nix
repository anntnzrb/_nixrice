# Machines tagged `desktop` (NixOS): startx-launched X, keyring and polkit.
{ pkgs, inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    keyd
    mullvad
    networkmanager
    pipewire
    sshd
    syncthing
    user
  ];

  services.xserver = {
    enable = true;
    autorun = false;
    excludePackages = with pkgs; [
      iceauth
      setxkbmap
      xset
      xsetroot
      xprop
      xterm
    ];

    displayManager.startx.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;
}
