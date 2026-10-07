{ pkgs, inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    keyd
    mullvad
    networkmanager
    pipewire
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
  environment.systemPackages = [ pkgs.networkmanagerapplet ];
}
