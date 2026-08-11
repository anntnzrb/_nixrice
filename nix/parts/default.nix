{ config, inputs, ... }:
let
  discovery = import ./foundation/discovery.nix {
    inherit inputs;
    inherit (config) processedFlake;
  };

  contextData = import ./foundation/contexts.nix {
    inputs = discovery.repositoryInputs;
    inherit (discovery)
      builderLib
      flakeInputs
      namespace
      nixRoot
      supportedSystems
      systemRecords
      ;
  };

  instantiateModule = discovery.instantiateModule contextData.packageContexts;
  moduleOutputs = discovery.moduleOutputs instantiateModule;
  platformModules = discovery.platformModules instantiateModule;
  homeModuleValues = discovery.homeModuleValues instantiateModule;

  systemData = import ./targets/systems.nix {
    inputs = discovery.repositoryInputs;
    inherit (discovery)
      builderLib
      homeRecords
      nixpkgs
      systemRecords
      ;
    inherit (contextData) baseSystemMetadata packageContexts;
    inherit homeModuleValues instantiateModule platformModules;
  };

  homeData = import ./targets/homes.nix {
    inputs = discovery.repositoryInputs;
    inherit (discovery)
      flakeInputs
      homeLib
      homeRecords
      namespace
      systemRecords
      ;
    inherit (contextData) packageContexts;
    inherit homeModuleValues instantiateModule;
    inherit (systemData) systemOutputs;
  };

  artifacts = import ./outputs/artifacts.nix {
    inherit (discovery)
      builderLib
      exportedLib
      flakeInputs
      homeRecords
      namespace
      repositoryInputs
      sourceRoot
      supportedSystems
      ;
    inherit (contextData) packageContexts;
    inherit (systemData) systemOutputs;
    inherit (homeData) homeOutputs;
    inherit moduleOutputs;
  };
in
{
  inherit (artifacts) flake perSystem systems;

  processedFlake = builtins.removeAttrs config.flake [
    "apps"
    "legacyPackages"
  ];
}
