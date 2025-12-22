{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.nix-spotlight.homeManagerModules.default ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.nix-spotlight.enable = true;
  };
}
