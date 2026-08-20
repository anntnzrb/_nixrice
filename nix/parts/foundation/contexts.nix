{
  inputs,
  flakeInputs,
  builderLib,
  namespace,
  nixRoot,
  supportedSystems,
  systemRecords,
}:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  mkSystemContext =
    system:
    let
      stableBase = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];
      };
      stableChannel = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];
      };
      unstableChannel = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      baseChannels = {
        nixpkgs = stableBase;
        nixpkgs-stable = stableChannel;
        nixpkgs-unstable = unstableChannel;
      };
      localOverlay = import (nixRoot + "/overlays/unstable/default.nix") {
        channels = baseChannels;
        inherit inputs;
        lib = builderLib;
        inherit namespace;
      };
      packageNamespace = lib.fix (
        packages:
        let
          packagePkgs = stableBase.extend (
            final: previous: ({ ${namespace} = packages; } // localOverlay final previous)
          );
          callPackage =
            path:
            let
              value = import path;
              args = {
                pkgs = packagePkgs;
                channels = baseChannels;
                lib = builderLib;
                inherit inputs;
                inherit namespace;
              };
            in
            if builtins.isFunction value then value args else value;
        in
        {
          default = callPackage (nixRoot + "/packages/default/default.nix");
          rice = callPackage (nixRoot + "/packages/rice/default.nix");
        }
      );
      pkgs = stableBase.extend (
        final: previous:
        ({ ${namespace} = packageNamespace; } // localOverlay final previous)
      );
      channels = baseChannels // {
        nixpkgs = pkgs;
      };
    in
    {
      inherit
        channels
        packageNamespace
        pkgs
        stableChannel
        unstableChannel
        ;
    };

  packageContexts = lib.genAttrs supportedSystems mkSystemContext;
  baseSystemMetadata = spec: {
    inherit (spec) target;
    inherit (spec) system;
    host = spec.name;
    systems = systemRecords;
    inputs = flakeInputs;
    inherit namespace;
  };
in
{
  inherit baseSystemMetadata packageContexts;
}
