{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    ./disk.nix
    bash
    cliproxyapi
    essentials
    systemd-boot
    t3
  ];

  home-manager.users.${lib.liberion.identity.user}.liberion.ai.t3.settings.backgroundActivity =
    {
      overrides = {
        providerHealthRefreshInterval = 15 * 60 * 1000;
        automaticGitFetchInterval = 0;
      };
    };

  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };
}
