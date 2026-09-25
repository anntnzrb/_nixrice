# Bridges hosted Home Manager users into NixOS/nix-darwin machines. Each home
# imports its module set itself (liberion homes: `modules/home.nix`).
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs; };
  };

  # nix-darwin leaves `home` null, which home-manager needs
  users.users = lib.mapAttrs (name: _: {
    home = lib.mkDefault (
      if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${name}" else "/home/${name}"
    );
  }) config.home-manager.users;
}
