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
