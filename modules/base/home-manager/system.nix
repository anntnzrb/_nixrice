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
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };

  users.users = lib.mapAttrs (name: _: {
    home = lib.mkDefault (
      if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${name}" else "/home/${name}"
    );
  }) config.home-manager.users;
}
