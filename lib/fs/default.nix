{ lib, ... }:
let
  repoRoot = ../../.;

  getFile = relPath: repoRoot + "/${relPath}";

  # Shallow: regular *.nix children minus default.nix and `ignore` names.
  getModuleFiles =
    {
      path,
      ignore ? [ ],
    }:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (
        name: kind:
        kind == "regular"
        && lib.hasSuffix ".nix" name
        && name != "default.nix"
        && !(builtins.elem name ignore)
      ))
      (lib.mapAttrsToList (name: _: path + "/${name}"))
    ];

  # Recursive: every default.nix below `path` (module roots).
  getDefaultFiles =
    path:
    lib.concatLists (
      lib.mapAttrsToList (
        name: kind:
        if kind == "directory" then
          getDefaultFiles (path + "/${name}")
        else if kind == "regular" && name == "default.nix" then
          [ (path + "/${name}") ]
        else
          [ ]
      ) (builtins.readDir path)
    );
in
{
  fs = { inherit getModuleFiles getFile getDefaultFiles; };
}
