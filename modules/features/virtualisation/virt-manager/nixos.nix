{ inputs, ... }: {
  imports = [ inputs.self.nixosModules.user ];

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
  };

  programs.virt-manager.enable = true;

  liberion.user.extraGroups = [ "libvirtd" ];
}
