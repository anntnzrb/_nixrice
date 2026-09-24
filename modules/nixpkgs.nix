# Machines build their package set from the flake's `nixpkgsArgs`, unless an
# instance is injected (clan passes `pkgsFor` for vars/clanInternals).
{
  lib,
  options,
  nixpkgsArgs,
  ...
}:
{
  nixpkgs = lib.mkIf (!options.nixpkgs.pkgs.isDefined) {
    inherit (nixpkgsArgs) config overlays;
  };
}
