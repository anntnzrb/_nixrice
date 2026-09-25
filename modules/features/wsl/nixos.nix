{ lib, inputs, ... }: {
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;
    defaultUser = lib.liberion.identity.user;
    docker-desktop.enable = true;
  };

  programs.nix-ld.enable = true;
}
