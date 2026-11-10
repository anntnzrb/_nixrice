{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkReq';

  cfg = config.liberion.network.tailscale;
  exposures = lib.attrValues cfg.expose;
in
{
  options.liberion.network.tailscale.expose = lib.liberion.module.mkOpt' (
    lib.types.attrsOf
      (
        lib.types.submodule {
          options = {
            port = mkReq' lib.types.port;
            target = mkReq' (
              lib.types.strMatching "https?://(127[.]0[.]0[.]1|localhost|[[]::1[]]):[0-9]+(/.*)?"
            );
            funnel = lib.liberion.module.mkOptDisabled';
          };
        }
      )
  ) { };

  config.assertions = [
    {
      assertion =
        lib.length (lib.unique (map (m: m.port) exposures)) == lib.length exposures;
      message = "Tailscale exposure mappings must own distinct HTTPS ports.";
    }
    {
      assertion = lib.all (
        m:
        !m.funnel
        || builtins.elem m.port [
          443
          8443
          10000
        ]
      ) exposures;
      message = "Tailscale Funnel supports HTTPS ports 443, 8443 and 10000.";
    }
  ];
}
