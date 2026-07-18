{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.services.tailscale;
in
{
  options.${namespace}.services.tailscale = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { services.tailscale.enable = true; };
}
