{
  lib,
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.environment;
in
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/environment/default.nix")
  ];

  config = { };
}
