{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.omnix;
in
{
  options.${namespace}.cli.omnix = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.om = "nix --accept-flake-config run github:juspay/omnix --";
  };
}
