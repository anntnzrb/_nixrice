{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  expected = import ./expected.nix;
  system = pkgs.stdenv.hostPlatform.system;
  outputs = builtins.removeAttrs inputs.self [ "outPath" ];

  isDerivation =
    value:
    builtins.isAttrs value
    && value ? type
    && builtins.isString value.type
    && value.type == "derivation";

  typeOf =
    value: if isDerivation value then "derivation" else builtins.typeOf value;

  attrTypes =
    value: names:
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = typeOf (builtins.getAttr name value);
      }) names
    );

  constantTypes =
    names: value:
    builtins.listToAttrs (builtins.map (name: { inherit name value; }) names);

  expectedFamilyKeys = {
    checks = expected.realSystems;
    darwinConfigurations = expected.configurations.darwin.keys;
    darwinModules = expected.moduleMaps.darwin;
    devShells = expected.realSystems;
    doConfigurations = expected.configurations.do.keys;
    formatter = expected.realSystems;
    homeConfigurations = expected.configurations.homes.keys;
    homeModules = expected.moduleMaps.home;
    isoConfigurations = expected.configurations.iso.keys;
    lib = expected.lib.keys;
    nixosConfigurations = expected.configurations.nixos.keys;
    nixosModules = expected.moduleMaps.nixos;
    overlays = expected.overlays.keys;
    packages = expected.realSystems;
    pkgs = expected.realSystems;
    snowfall = expected.snowfall.keys;
    templates = expected.templates.keys;
  };

  actualFamilyKeys = builtins.listToAttrs (
    builtins.map (name: {
      inherit name;
      value = builtins.attrNames (builtins.getAttr name outputs);
    }) expected.topLevel
  );

  actualFamilyTypes = builtins.listToAttrs (
    builtins.map (name: {
      inherit name;
      value = typeOf (builtins.getAttr name outputs);
    }) expected.topLevel
  );

  configurationSurface =
    family: spec:
    let
      value = builtins.getAttr family outputs;
    in
    builtins.attrNames value == spec.keys
    && builtins.all (
      name: typeOf (builtins.getAttr name value) == spec.valueType
    ) spec.keys;

  normalizedCheckKeys =
    checkSystem:
    builtins.filter (name: name != "composition-regression") (
      builtins.attrNames (builtins.getAttr checkSystem outputs.checks)
    );

  standardSurface =
    output: keyFunction:
    let
      systems = builtins.attrNames output;
    in
    {
      type = typeOf output;
      inherit systems;
      systemTypes = attrTypes output systems;
      keys = builtins.listToAttrs (
        builtins.map (name: {
          inherit name;
          value = keyFunction name;
        }) systems
      );
    };

  standardSurfacePass =
    actual: spec:
    actual.type == spec.type
    && actual.systems == expected.realSystems
    && actual.systemTypes == constantTypes expected.realSystems spec.systemType
    && actual.keys == spec.keys;

  valueTypesPass =
    output: keyFunction: expectedType:
    builtins.all (
      systemName:
      let
        values = builtins.getAttr systemName output;
      in
      builtins.all (name: typeOf (builtins.getAttr name values) == expectedType) (
        keyFunction systemName
      )
    ) expected.realSystems;

  actualDevShells = standardSurface outputs.devShells (
    systemName: builtins.attrNames (builtins.getAttr systemName outputs.devShells)
  );
  actualChecks = standardSurface outputs.checks normalizedCheckKeys;

  actualFormatter =
    let
      inherit (outputs) formatter;
      systems = builtins.attrNames formatter;
    in
    {
      type = typeOf formatter;
      inherit systems;
      systemTypes = attrTypes formatter systems;
    };

  actualPkgs = outputs.pkgs;
  # R0a captured channel names, not leaf package-set values. Do not force leaf values:
  # current nixpkgs-unstable does not evaluate x86_64-darwin, and R0a recorded no leaf types.
  pkgsChannelsPass =
    typeOf actualPkgs == expected.pkgs.type
    && builtins.attrNames actualPkgs == expected.realSystems
    && builtins.all (
      systemName:
      let
        channels = builtins.getAttr systemName actualPkgs;
        channelNames = builtins.attrNames channels;
      in
      typeOf channels == expected.pkgs.systemType
      && channelNames == builtins.getAttr systemName expected.pkgs.systems
    ) expected.realSystems;

  overlayNames = expected.overlays.keys;
  overlaysPass =
    typeOf outputs.overlays == expected.overlays.type
    && builtins.attrNames outputs.overlays == overlayNames
    &&
      attrTypes outputs.overlays overlayNames
      == constantTypes overlayNames expected.overlays.valueType;

  packageMap = builtins.getAttr system outputs.packages;
  homeAliases = builtins.filter (name: lib.hasPrefix "homeConfigurations-" name) (
    builtins.attrNames packageMap
  );
  aliasPasses = builtins.map (
    alias:
    let
      homeName = lib.removePrefix "homeConfigurations-" alias;
      home = builtins.getAttr homeName outputs.homeConfigurations;
      activation = home.activationPackage;
      package = builtins.getAttr alias packageMap;
    in
    {
      label = "packages.${system}.${alias} points to homeConfigurations.${homeName}.activationPackage";
      pass =
        isDerivation package
        && isDerivation activation
        && package.drvPath == activation.drvPath;
    }
  ) homeAliases;

  preCommit = (builtins.getAttr system outputs.checks).pre-commit-hooks;
  shell = (builtins.getAttr system outputs.devShells).default;
  formatter = builtins.getAttr system outputs.formatter;
  preCommitShapePass =
    isDerivation preCommit
    && builtins.isAttrs preCommit.config
    && builtins.hasAttr "gitPackage" preCommit.config
    && builtins.hasAttr "package" preCommit.config
    && builtins.hasAttr "configFile" preCommit.config
    && builtins.hasAttr "enabledPackages" preCommit
    && builtins.isList preCommit.enabledPackages
    && builtins.hasAttr "shellHook" preCommit
    && builtins.isString preCommit.shellHook;

  moduleFiles = inputs.self.lib.fs.getModuleFiles {
    path = ./../../modules/home/shells/zellij;
    ignore = [ "plugins.nix" ];
  };
  moduleFileNames = builtins.map builtins.baseNameOf moduleFiles;

  hostedUserPresent =
    systemConfiguration:
    builtins.hasAttr "annt" systemConfiguration.config."home-manager".users;

  homeSystem =
    name:
    let
      home = builtins.getAttr name outputs.homeConfigurations;
    in
    home.pkgs.stdenv.hostPlatform.system;

  virtualShapePass =
    value:
    isDerivation value
    && value.system == "x86_64-linux"
    && builtins.hasAttr "name" value
    && builtins.isString value.name
    && builtins.hasAttr "builder" value
    && builtins.hasAttr "args" value
    && builtins.hasAttr "outputs" value;

  assertions = [
    {
      label = "R0a top-level output families";
      pass = builtins.attrNames outputs == expected.topLevel;
    }
    {
      label = "R0a top-level output family types";
      pass = actualFamilyTypes == expected.topLevelTypes;
    }
    {
      label = "R0a selected family key manifest";
      pass = actualFamilyKeys == expectedFamilyKeys;
    }
    {
      label = "ordinary Darwin configuration names and types";
      pass = configurationSurface "darwinConfigurations" expected.configurations.darwin;
    }
    {
      label = "ordinary NixOS configuration names and types";
      pass = configurationSurface "nixosConfigurations" expected.configurations.nixos;
    }
    {
      label = "DigitalOcean virtual configuration name and derivation type";
      pass = configurationSurface "doConfigurations" expected.configurations.do;
    }
    {
      label = "ISO virtual configuration name and derivation type";
      pass = configurationSurface "isoConfigurations" expected.configurations.iso;
    }
    {
      label = "Home Manager configuration names and types";
      pass = configurationSurface "homeConfigurations" expected.configurations.homes;
    }
    {
      label = "NixOS recursive module-map keys";
      pass = builtins.attrNames outputs.nixosModules == expected.moduleMaps.nixos;
    }
    {
      label = "Darwin recursive module-map keys";
      pass = builtins.attrNames outputs.darwinModules == expected.moduleMaps.darwin;
    }
    {
      label = "Home recursive module-map keys";
      pass = builtins.attrNames outputs.homeModules == expected.moduleMaps.home;
    }
    {
      label = "devShells per-system key/type surface";
      pass =
        standardSurfacePass actualDevShells expected.perSystem.devShells
        && valueTypesPass outputs.devShells (
          systemName: builtins.attrNames (builtins.getAttr systemName outputs.devShells)
        ) expected.perSystem.devShells.valueType;
    }
    {
      label = "checks per-system key/type surface excluding this check";
      pass =
        standardSurfacePass actualChecks expected.perSystem.checks
        &&
          valueTypesPass outputs.checks normalizedCheckKeys
            expected.perSystem.checks.valueType;
    }
    {
      label = "formatter per-system derivation surface";
      pass =
        actualFormatter.type == expected.topLevelTypes.formatter
        && actualFormatter.systems == expected.perSystem.formatter.systems
        &&
          actualFormatter.systemTypes
          == constantTypes expected.perSystem.formatter.systems expected.perSystem.formatter.type;
    }
    {
      label = "pkgs channel fixed-point keys and types";
      pass = pkgsChannelsPass;
    }
    {
      label = "exported overlay keys and function values";
      pass = overlaysPass;
    }
    {
      label = "aarch64-darwin host output mapping";
      pass =
        outputs.darwinConfigurations.beirut.pkgs.stdenv.hostPlatform.system
        == "aarch64-darwin"
        &&
          outputs.darwinConfigurations.incheon.pkgs.stdenv.hostPlatform.system
          == "aarch64-darwin";
    }
    {
      label = "x86_64-linux host output mapping";
      pass =
        outputs.nixosConfigurations.munich.pkgs.stdenv.hostPlatform.system
        == "x86_64-linux"
        &&
          outputs.nixosConfigurations.solna.pkgs.stdenv.hostPlatform.system
          == "x86_64-linux"
        &&
          outputs.nixosConfigurations.tampa.pkgs.stdenv.hostPlatform.system
          == "x86_64-linux"
        &&
          outputs.nixosConfigurations.zadar.pkgs.stdenv.hostPlatform.system
          == "x86_64-linux";
    }
    {
      label = "virtual outputs retain Linux derivation shape without realization";
      pass =
        virtualShapePass outputs.doConfigurations.nista
        && virtualShapePass outputs.isoConfigurations.nomad;
    }
    {
      label = "virtual outputs are absent from nixosConfigurations";
      pass =
        !(outputs.nixosConfigurations ? nista)
        && !(outputs.nixosConfigurations ? nomad);
    }
    {
      label = "hosted Home Manager users are associated with beirut/incheon/zadar";
      pass =
        hostedUserPresent outputs.darwinConfigurations.beirut
        && hostedUserPresent outputs.darwinConfigurations.incheon
        && hostedUserPresent outputs.nixosConfigurations.zadar;
    }
    {
      label = "standalone annt@wsl home has no parent system";
      pass =
        !(outputs.nixosConfigurations ? wsl)
        && !(outputs.darwinConfigurations ? wsl)
        && outputs.homeConfigurations."annt@wsl".config.home.username == "annt"
        &&
          outputs.homeConfigurations."annt@wsl".config.home.homeDirectory == "/home/annt"
        && homeSystem "annt@wsl" == "x86_64-linux";
    }
    {
      label = "hosted home output target mappings";
      pass =
        homeSystem "annt@beirut" == "aarch64-darwin"
        && homeSystem "annt@incheon" == "aarch64-darwin"
        && homeSystem "annt@zadar" == "x86_64-linux";
    }
    {
      label = "package namespace fixed point exposes default and rice";
      pass =
        isDerivation packageMap.default
        && isDerivation packageMap.rice
        && packageMap.default.name == packageMap.rice.name;
    }
    {
      label = "pre-commit-hooks derivation and configuration shape";
      pass = preCommitShapePass;
    }
    {
      label = "devShell inherits the pre-commit shellHook";
      pass = isDerivation shell && shell.shellHook == preCommit.shellHook;
    }
    {
      label = "formatter derivation has the stable name";
      pass = isDerivation formatter && formatter.name == "formatter";
    }
    {
      label = "getModuleFiles is shallow and honors ignore on zellij fixture";
      pass =
        moduleFileNames == [
          "keybinds.nix"
          "layouts.nix"
          "themes.nix"
        ];
    }
    {
      label = "composition-regression check is exposed without forcing itself";
      pass = builtins.hasAttr "composition-regression" (
        builtins.getAttr system outputs.checks
      );
    }
  ]
  ++ aliasPasses;

  failures = builtins.filter (assertion: !assertion.pass) assertions;
  failureMessage =
    "composition-regression failures:\n  "
    + lib.concatStringsSep "\n  " (
      builtins.map (assertion: assertion.label) failures
    );
in
assert lib.assertMsg (builtins.length failures == 0) failureMessage;
pkgs.runCommand "composition-regression-${system}" { } ''
  touch "$out"
''
