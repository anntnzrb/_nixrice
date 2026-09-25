# Repository helpers exposed as `lib.liberion`.
{ lib }:
let
  # Description-free option (no generated option docs).
  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };
in
{
  fs = {
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

    # Recursive: every default.nix below `dir` (module roots).
    getDefaultFiles =
      dir:
      builtins.filter (p: baseNameOf p == "default.nix") (
        lib.filesystem.listFilesRecursive dir
      );
  };

  module = {
    inherit mkOpt';
    mkOptEnabled' = mkOpt' lib.types.bool true; # default-on baseline
    mkOptDisabled' = mkOpt' lib.types.bool false; # opt-in feature
    on.enable = true;
    off.enable = false;
  };

  xorg.mkAutostartScript = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
}
