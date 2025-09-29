{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) off;

  cfg = config.${namespace}.nix;
in
{
  imports = [
    (lib.snowfall.fs.get-file "modules/shared/nix/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    nix = off;
  };
}
