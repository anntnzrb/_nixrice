{ inputs, lib, ... }: {
  imports = [ inputs.self.nixosModules.user ];

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
  };

  programs.virt-manager.enable = true;

  users.users.${lib.liberion.identity.user}.extraGroups = [ "libvirtd" ];
}
