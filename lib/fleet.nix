{
  identity,
  lib,
  root,
}:
let
  isAdmin = machine: builtins.elem "admin" machine.tags;
  isArchived = machine: builtins.elem "archived" machine.tags;
  mdnsDomain = "local";

  fleetPeers =
    machines: self:
    lib.filterAttrs (_: machine: !(isArchived machine)) (
      removeAttrs machines [ self ]
    );

  varValue =
    path:
    let
      file = root + "/vars/${path}/value";
    in
    if builtins.pathExists file then lib.trim (builtins.readFile file) else null;

  adminValues =
    machines: file:
    lib.filter (value: value != null) (
      lib.mapAttrsToList (name: _: varValue "per-machine/${name}/${file}") (
        lib.filterAttrs (_: isAdmin) machines
      )
    );

  adminAgeKeys =
    machines:
    [ identity.keys.adminAge ] ++ adminValues machines "admin-age/key.pub";
in
{
  inherit
    isArchived
    fleetPeers
    mdnsDomain
    varValue
    adminValues
    adminAgeKeys
    ;

  authorizedKeys = [ identity.keys.admin ] ++ identity.keys.devices;

  tailscaleExpose =
    tailscale: name: mapping:
    let
      mode = if mapping.funnel then "funnel" else "serve";
      command = "${tailscale} ${mode}";
    in
    {
      description = "Tailscale ${
        if mapping.funnel then "Funnel" else "Serve"
      } mapping ${name}";
      start = "${command} --bg --https=${toString mapping.port} ${mapping.target}";
      stop = "${command} --https=${toString mapping.port} off";
    };
}
