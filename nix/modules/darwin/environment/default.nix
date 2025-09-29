{
  lib,
  ...
}:
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/environment/default.nix")
  ];
}
