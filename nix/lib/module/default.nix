{ lib, ... }:
{
  module = rec {
    # ---------------------------------------------------------------------------
    # Option Helpers
    # ---------------------------------------------------------------------------

    # Creates an option with the specified type, default value, and description.
    # Alias for mkOption.
    mkOpt =
      type: default: description:
      lib.mkOption { inherit type default description; };

    # Creates an option with the specified type and default value, no description.
    # Alias for mkOption.
    mkOpt' = type: def: mkOpt type def null;

    # Creates a boolean option defaulting to true, with given description.
    # Alias for mkOption.
    mkOptEnabled = desc: mkOpt lib.types.bool true desc;

    # Creates a boolean option defaulting to true, no description.
    # Alias for mkOption.
    mkOptEnabled' = mkOpt lib.types.bool true null;

    # Creates a boolean option defaulting to false, with given description.
    # Alias for mkOption.
    mkOptDisabled = desc: mkOpt lib.types.bool false desc;

    # Creates a boolean option defaulting to false, no description.
    # Alias for mkOption.
    mkOptDisabled' = mkOpt lib.types.bool false null;

    # Alias for enabling an option.
    on.enable = true;

    # Alias for disabling an option.
    off.enable = false;

    # ---------------------------------------------------------------------------
    # File Discovery
    # ---------------------------------------------------------------------------

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

    ## Get importable module files (*.nix except default.nix), with ignore list.
    ## Usage: getModuleFiles ./. [ "lib.nix" "helpers.nix" ]
    #@ Path -> [String] -> [Path]
    getModuleFiles =
      path: ignore:
      builtins.filter (
        f:
        let
          name = baseNameOf f;
        in
        isNixFile f && name != "default.nix" && !(builtins.elem name ignore)
      ) (getFiles path);

    ## Prime variant: no ignore list.
    ## Usage: getModuleFiles' ./.
    #@ Path -> [Path]
    getModuleFiles' = path: getModuleFiles path [ ];

    ## Recursive variant with ignore list.
    #@ Path -> [String] -> [Path]
    getModuleFilesRecursive =
      path: ignore:
      let
        entries = builtins.readDir path;
        process =
          name: kind:
          let
            fullPath = path + "/${name}";
            baseName = baseNameOf fullPath;
          in
          if kind == "directory" then
            getModuleFilesRecursive fullPath ignore
          else if kind == "regular" then
            if
              isNixFile fullPath
              && baseName != "default.nix"
              && !(builtins.elem baseName ignore)
            then
              [ fullPath ]
            else
              [ ]
          else
            [ ];
      in
      lib.flatten (lib.mapAttrsToList process entries);

    ## Recursive prime variant: no ignore list.
    #@ Path -> [Path]
    getModuleFilesRecursive' = path: getModuleFilesRecursive path [ ];
  };
}
