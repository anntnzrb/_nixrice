{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  cacheClean = pkgs.writeShellApplication {
    name = "streaming-cache-clean";
    runtimeInputs = [ pkgs.findutils ] ++ lib.optional (!isDarwin) pkgs.procps;
    runtimeEnv = {
      PGREP = if isDarwin then "/usr/bin/pgrep" else "pgrep";
      CACHE_SUBDIR =
        if isDarwin then
          "Library/Application Support/stremio-server/stremio-cache"
        else
          ".stremio-server/stremio-cache";
    };
    text = builtins.readFile ./cache-clean.sh;
  };
in
{
  liberion.maintenance.tasks.stremio.command = [ (lib.getExe cacheClean) ];
}
