{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.cli.omnix;
in
{
  options.${namespace}.cli.omnix = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.om = "nix --accept-flake-config run github:juspay/omnix --";
  };
}
