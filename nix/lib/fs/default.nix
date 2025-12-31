{ lib, ... }:
{
  fs = rec {
    ## Get all regular files in a directory.
    #@ Path -> [Path]
    getFiles =
      path:
      lib.pipe (builtins.readDir path) [
        (lib.filterAttrs (_: kind: kind == "regular"))
        (lib.mapAttrsToList (name: _: path + "/${name}"))
      ];

    ## Check if path has .nix extension.
    #@ Path -> Bool
    isNixFile = path: lib.hasSuffix ".nix" (baseNameOf path);

    ## Get importable module files (*.nix except default.nix).
    ## Usage: getModuleFiles { path = ./.; }
    ##        getModuleFiles { path = ./.; ignore = [ "lib.nix" ]; }
    #@ { path :: Path, ignore :: [String] } -> [Path]
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
  };
}
