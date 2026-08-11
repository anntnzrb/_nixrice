{ config, inputs, ... }:
let
  composition = config.liberion.composition;
  inherit (composition)
    builderLib
    flakeInputs
    namespace
    realSystems
    root
    systemRecords
    ;
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
      localOverlay = import (root + "/overlays/nixpkgs-unstable/default.nix") {
        channels = baseChannels;
        inputs = flakeInputs;
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
                inputs = flakeInputs;
                inherit namespace;
              };
            in
            if builtins.isFunction value then value args else value;
        in
        {
          default = callPackage (root + "/packages/default/default.nix");
          rice = callPackage (root + "/packages/rice/default.nix");
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

  contexts = lib.genAttrs realSystems mkSystemContext;
  baseSystemMetadata = spec: {
    inherit (spec) target;
    inherit (spec) system;
    inherit (spec) format;
    inherit (spec) virtual;
    host = spec.name;
    systems = systemRecords;
    inputs = flakeInputs;
    inherit namespace;
  };
in
{
  config.liberion.composition = { inherit baseSystemMetadata contexts; };
}
