{ lib, ... }:
let
  repoRoot = ../../.;

  /**
    Get a repo-relative file.

    # Example

    ```nix
    getFile "modules/shared/nix/default.nix"
    =>
    /path/to/repo/modules/shared/nix/default.nix
    ```

    # Type

    ```
    getFile :: String -> Path
    ```
  */
  getFile = relPath: repoRoot + "/${relPath}";

  /**
    Get all regular files in a directory.
    Shallow: only direct children whose `readDir` kind is `regular`.

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
    Shallow: considers only direct regular files from getFiles.

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

  /**
    Recursively collect every `default.nix` below a directory (module roots).

    # Example

    ```nix
    getDefaultFiles ./modules/home
    =>
    [ ./modules/home/default.nix ./modules/home/cli/git/default.nix ]
    ```

    # Type

    ```
    getDefaultFiles :: Path -> [Path]
    ```
  */
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
  fs = {
    inherit
      getFiles
      isNixFile
      getModuleFiles
      getFile
      getDefaultFiles
      ;
  };
}
