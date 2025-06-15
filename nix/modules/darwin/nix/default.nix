{
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.nix;
in
{
  config.nix.enable = false;
}
