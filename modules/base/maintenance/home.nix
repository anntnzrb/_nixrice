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

  uvPrune = pkgs.writeShellScript "maintenance-uv" ''
    if ! command -v uv >/dev/null 2>&1; then
      exit 0
    fi
    cache_dir="$(uv cache dir 2>/dev/null || true)"
    if [ -n "$cache_dir" ] && [ -d "$cache_dir" ]; then
      exec uv cache prune
    fi
  '';

  bunClean = pkgs.writeShellScript "maintenance-bun" ''
    for cache_dir in "$HOME/.bun/install/cache" "''${XDG_CACHE_HOME:-$HOME/.cache}/.bun/install/cache"; do
      if [ -d "$cache_dir" ]; then
        find "$cache_dir" -mindepth 1 -delete 2>/dev/null || true
      fi
    done
  '';

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

  config = lib.mkMerge [
    {
      liberion.maintenance.tasks = {
        uv.command = [ "${uvPrune}" ];
        bun.command = [ "${bunClean}" ];
        scratch.command = [ (lib.getExe scratch) ];
      };
    }
    (lib.liberion.userJob {
      name = "maintenance";
      description = "Reclaim package caches and stale scratch";
      command = [ "${runner}" ];
      schedule = "nightly";
      timeout = 1800;
    } { inherit config pkgs; })
  ];
}
