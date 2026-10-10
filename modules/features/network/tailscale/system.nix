{ config, lib, ... }:
let
  cfg = config.liberion.network.tailscale;
in
{
  options.liberion.network.tailscale.expose = lib.liberion.module.mkOpt' (
    lib.types.attrsOf
      (
        lib.types.submodule {
          options = {
            port = lib.liberion.module.mkReq' lib.types.port;
            target = lib.liberion.module.mkReq' (
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
        lib.length (lib.unique (map (m: m.port) (lib.attrValues cfg.expose)))
        == lib.length (lib.attrValues cfg.expose);
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
      ) (lib.attrValues cfg.expose);
      message = "Tailscale Funnel supports HTTPS ports 443, 8443 and 10000.";
    }
  ];
}
