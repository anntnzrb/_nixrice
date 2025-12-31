{ lib, ... }:
let
  /**
    Get all regular files in a directory.

    # Example

    ```nix
    getFiles ./my-module
    =>
    [ ./my-module/foo.nix ./my-module/bar.txt ]
    ```

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

    # Example

    ```nix
    isNixFile ./foo.nix
    =>
    true

    isNixFile ./bar.txt
    =>
    false
    ```

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
    getModuleFiles { path = ./my-module; }
    =>
    [ ./my-module/foo.nix ./my-module/bar.nix ]

    getModuleFiles { path = ./my-module; ignore = [ "lib.nix" ]; }
    =>
    [ ./my-module/foo.nix ./my-module/bar.nix ]
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
in
{
  fs = {
    inherit getFiles isNixFile getModuleFiles;
  };
}
