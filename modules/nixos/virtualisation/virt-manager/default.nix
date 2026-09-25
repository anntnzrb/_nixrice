import ../../../toggle.nix "virtualisation.virt-manager" (_: {
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
  };

  programs.virt-manager.enable = true;

  liberion.user.extraGroups = [ "libvirtd" ];
})
