{
  repositoryInputs,
  builderLib,
  exportedLib,
  flakeInputs,
  homeOutputs,
  homeRecords,
  moduleOutputs,
  namespace,
  packageContexts,
  sourceRoot,
  supportedSystems,
  systemOutputs,
}:
let
  inherit (repositoryInputs.nixpkgs) lib;

  checkEntrypoint = sourceRoot + "/checks/pre-commit-hooks/default.nix";
  compositionRegressionEntrypoint =
    sourceRoot + "/checks/composition-regression/default.nix";
  shellEntrypoint = sourceRoot + "/shells/default/default.nix";

  checkForSystem =
    system:
    let
      context = packageContexts.${system};
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
      context = packageContexts.${system};
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
    system: preCommit:
    let
      context = packageContexts.${system};
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
          value = homeOutputs.homeConfigurations.${home.name}.activationPackage;
        })
        (
          builtins.filter (home: home.system == system) (builtins.attrValues homeRecords)
        )
    );

  packageForSystem =
    system: packageContexts.${system}.packageNamespace // activationAliases system;

  exportedOverlays =
    let
      packageOverlay =
        name: final: previous:
        let
          system = final.stdenv.hostPlatform.system;
          packages = packageContexts.${system}.packageNamespace;
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
          context = packageContexts.${system};
          overlay = import (sourceRoot + "/overlays/unstable/default.nix") {
            inherit (context) channels;
            inputs = repositoryInputs;
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
      unstable = localOverlay;
      default = defaultOverlay;
    };
in
{
  systems = supportedSystems;
  perSystem =
    { system, ... }:
    let
      checks = checkForSystem system;
    in
    {
      packages = packageForSystem system;
      inherit checks;
      devShells = shellForSystem system;
      formatter = formatterForSystem system checks.pre-commit-hooks;
    };
  flake = {
    inherit (systemOutputs) darwinConfigurations nixosConfigurations;
    inherit (homeOutputs) homeConfigurations;
    inherit (moduleOutputs) nixosModules darwinModules homeModules;
    lib = exportedLib;
    overlays = exportedOverlays;
    pkgs = lib.genAttrs supportedSystems (
      system: packageContexts.${system}.channels
    );
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
}
