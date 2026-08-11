{ lib, ... }:
let
  internal = lib.mkOption {
    type = lib.types.raw;
    internal = true;
  };
in
{
  options.liberion.composition = {
    namespace = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
    };
    realSystems = internal;
    root = internal;
    sourceRoot = internal;
    nixpkgs = internal;
    flakeInputs = internal;
    systemRecords = internal;
    homeRecords = internal;
    builderLib = internal;
    repositoryLib = internal;
    exportedLib = internal;
    homeLib = internal;
    moduleWrapper = internal;
    modulePaths = internal;
    moduleOutputs = internal;
    platformModules = internal;
    homeModuleValues = internal;
    contexts = internal;
    baseSystemMetadata = internal;
    systemOutputs = internal;
    homeOutputs = internal;
  };
}
