{ lib, ... }:
let
  repoRoot = ../../.;

  getFile = relPath: repoRoot + "/${relPath}";

  # Shallow: only direct children whose readDir kind is regular.
  getFiles =
    path:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (_: kind: kind == "regular"))
      (lib.mapAttrsToList (name: _: path + "/${name}"))
    ];

  isNixFile = path: lib.hasSuffix ".nix" (baseNameOf path);

  # Shallow: *.nix files from getFiles minus default.nix and `ignore` names.
  getModuleFiles =
    {
      path,
      ignore ? [ ],
    }:
    builtins.filter (
      f:
      let
        name = baseNameOf f;
      in
      isNixFile f && name != "default.nix" && !(builtins.elem name ignore)
    ) (getFiles path);

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
