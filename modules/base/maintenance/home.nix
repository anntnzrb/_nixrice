{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.maintenance;

  sortedTaskNames = lib.sort (a: b: a < b) (builtins.attrNames cfg.tasks);

  scratch = lib.liberion.pythonScript pkgs {
    name = "scratch";
    script = ./scratch.py;
  };

  runner = pkgs.writeShellScript "maintenance-runner" ''
    set -u
    failed=0
    ${lib.concatStringsSep "\n" (
      map (name: ''
        echo "maintenance: [${name}] running..."
        if ${lib.escapeShellArgs cfg.tasks.${name}.command}; then
          echo "maintenance: [${name}] ok"
        else
          echo "maintenance: [${name}] failed (exit $?)" >&2
          failed=1
        fi
      '') sortedTaskNames
    )}
    exit "$failed"
  '';
in
{
  imports = [
    (lib.liberion.userJob {
      name = "maintenance";
      description = "Reclaim package caches and stale scratch";
      command = [ "${runner}" ];
      schedule = "nightly";
      timeout = 1800;
    })
  ];

  options.liberion.maintenance.tasks = lib.liberion.module.mkOpt' (
    lib.types.attrsOf
      (
        lib.types.submodule {
          options = {
            command = lib.liberion.module.mkReq' (lib.types.listOf lib.types.str);
          };
        }
      )
  ) { };

  config.liberion.maintenance.tasks.scratch.command = [ (lib.getExe scratch) ];
}
