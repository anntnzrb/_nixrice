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
