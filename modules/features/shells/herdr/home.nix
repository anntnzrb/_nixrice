{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  session = "default";
  endpoints = (pkgs.formats.json { }).generate "herdr-endpoints.json" {
    version = 1;
    ssh =
      lib.mapAttrsToList
        (name: _: {
          id = builtins.hashString "md5" "${name}\n${session}";
          label = name;
          target = name;
          inherit session;
          enabled = true;
        })
        (
          lib.liberion.fleetPeers inputs.self.clan.inventory.machines osConfig.clan.core.settings.machine.name
        );
  };
in
{
  xdg.configFile."herdr/config.toml" = {
    source = ./config.toml;
    onChange = "${lib.getExe pkgs.unstable.herdr} server reload-config || true";
  };

  home = {
    packages = [ pkgs.unstable.herdr ];

    activation.herdrMachines = lib.mkIf config.submoduleSupport.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe' pkgs.coreutils "install"} -Dm600 ${endpoints} \
          ${lib.escapeShellArg "${config.xdg.stateHome}/herdr/client/endpoints.json"}
      ''
    );
  };
}
