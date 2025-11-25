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
    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts.
    # https://docs.determinate.systems/guides/nix-darwin
    nix = off;
  };
}
