{
  lib,
  namespace,
  ...
}:
{
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/environment/default.nix")
  ];
}
