{ lib, ... }:
{
  fs = rec {
    /**
      Get all regular files in a directory.

      # Type

      ```
      getFiles :: Path -> [Path]
      ```
    */
    getFiles =
      path:
      lib.pipe (builtins.readDir path) [
        (lib.filterAttrs (_: kind: kind == "regular"))
        (lib.mapAttrsToList (name: _: path + "/${name}"))
      ];

    /**
      Check if path has .nix extension.

      # Type

      ```
      isNixFile :: Path -> Bool
      ```
    */
    isNixFile = path: lib.hasSuffix ".nix" (baseNameOf path);

    /**
      Get importable module files (*.nix except default.nix).

      # Example

      ```nix
      getModuleFiles { path = ./.; }
      =>
      [ ./foo.nix ./bar.nix ]

      getModuleFiles { path = ./.; ignore = [ "lib.nix" ]; }
      =>
      [ ./foo.nix ./bar.nix ]
      ```

      # Type

      ```
      getModuleFiles :: { path :: Path, ignore :: [String] } -> [Path]
      ```

      # Arguments

      path
      : The directory to scan for module files

      ignore
      : List of filenames to exclude (default: [])
    */
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
