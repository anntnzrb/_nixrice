{ config, inputs, ... }:
let
  composition = config.liberion.composition;
  inherit (inputs.nixpkgs) lib;
  inherit (composition)
    builderLib
    contexts
    exportedLib
    flakeInputs
    homeOutputs
    moduleOutputs
    namespace
    realSystems
    sourceRoot
    systemOutputs
    ;

  checkEntrypoint = sourceRoot + "/checks/pre-commit-hooks/default.nix";
  compositionRegressionEntrypoint =
    sourceRoot + "/checks/composition-regression/default.nix";
  shellEntrypoint = sourceRoot + "/shells/default/default.nix";

  checkForSystem =
    system:
    let
      context = contexts.${system};
      preCommit = import checkEntrypoint;
      compositionRegression = import compositionRegressionEntrypoint;
      args = {
        inherit (context) pkgs;
        lib = builderLib;
        inputs = flakeInputs;
        inherit (context) channels;
        inherit namespace;
      };
    in
    {
      pre-commit-hooks =
        if builtins.isFunction preCommit then preCommit args else preCommit;
      composition-regression =
        if builtins.isFunction compositionRegression then
          compositionRegression args
        else
          compositionRegression;
    };

  shellForSystem =
    system:
    let
      context = contexts.${system};
      value = import shellEntrypoint;
      args = {
        inherit (context) pkgs;
        lib = builderLib;
        inputs = flakeInputs;
        inherit (context) channels;
        inherit namespace;
      };
    in
    {
      default = if builtins.isFunction value then value args else value;
    };

  formatterForSystem =
    system:
    let
      context = contexts.${system};
      preCommit = flakeInputs.self.checks.${system}.pre-commit-hooks;
    in
    context.pkgs.writeShellApplication {
      name = "formatter";
      runtimeInputs = [
        preCommit.config.gitPackage
        preCommit.config.package
      ]
      ++ preCommit.enabledPackages;
      text = ''
        ${context.pkgs.lib.getExe preCommit.config.package} run --all-files -c ${preCommit.config.configFile}
      '';
    };

  activationAliases =
    system:
    lib.listToAttrs (
      builtins.map
        (home: {
          name = "homeConfigurations-${home.name}";
          value = flakeInputs.self.homeConfigurations.${home.name}.activationPackage;
        })
        (
          builtins.filter (home: home.system == system) (
            builtins.attrValues composition.homeRecords
          )
        )
    );

  packageForSystem =
    system: contexts.${system}.packageNamespace // activationAliases system;

  exportedOverlays =
    let
      packageOverlay =
        name: final: previous:
        let
          system = final.stdenv.hostPlatform.system;
          packages = contexts.${system}.packageNamespace;
        in
        {
          ${namespace} = (previous.${namespace} or { }) // {
            ${name} = packages.${name};
          };
        };
      localOverlay =
        final: previous:
        let
          system = final.stdenv.hostPlatform.system;
          context = contexts.${system};
          overlay = import (sourceRoot + "/overlays/nixpkgs-unstable/default.nix") {
            inherit (context) channels;
            inputs = flakeInputs;
            lib = builderLib;
            inherit namespace;
          };
        in
        overlay final previous;
      defaultOverlay =
        final: previous:
        let
          default = packageOverlay "default" final previous;
          rice = packageOverlay "rice" final previous;
          local = localOverlay final previous;
        in
        default
        // rice
        // local
        // {
          ${namespace} =
            (default.${namespace} or { })
            // (rice.${namespace} or { })
            // (local.${namespace} or { });
        };
    in
    {
      "package/default" = packageOverlay "default";
      "package/rice" = packageOverlay "rice";
      nixpkgs-unstable = localOverlay;
      default = defaultOverlay;
    };
in
{
  config = {
    systems = realSystems;
    perSystem = { system, ... }: {
      packages = packageForSystem system;
      checks = checkForSystem system;
      devShells = shellForSystem system;
      formatter = formatterForSystem system;
    };

    flake = {
      inherit (systemOutputs)
        darwinConfigurations
        nixosConfigurations
        doConfigurations
        isoConfigurations
        ;
      inherit (homeOutputs) homeConfigurations;
      inherit (moduleOutputs) nixosModules darwinModules homeModules;
      lib = exportedLib;
      overlays = exportedOverlays;
      pkgs = lib.genAttrs realSystems (system: contexts.${system}.channels);
      snowfall = {
        config = {
          inherit namespace;
          src = sourceRoot;
        };
        raw-config = { inherit namespace; };
        user-lib = exportedLib;
      };
      templates = { };
    };

    processedFlake = builtins.removeAttrs config.flake [
      "apps"
      "legacyPackages"
    ];
  };
}
