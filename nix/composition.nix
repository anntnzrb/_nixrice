{ inputs, self }:
let
  namespace = "liberion";
  realSystems = [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
  ];
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  flakeInputs = inputs // {
    inherit self;
  };

  directDirectories =
    root:
    let
      entries = builtins.readDir root;
    in
    builtins.filter (name: entries.${name} == "directory") (
      builtins.attrNames entries
    );

  recursiveDefaultFiles =
    root:
    let
      walk =
        directory:
        let
          entries = builtins.readDir directory;
          names = builtins.attrNames entries;
        in
        builtins.concatLists (
          builtins.map (
            name:
            let
              path = directory + "/${name}";
              kind = entries.${name};
            in
            if kind == "directory" then
              walk path
            else if kind == "regular" && name == "default.nix" then
              [ path ]
            else
              [ ]
          ) names
        );
    in
    walk root;

  targetFirstRecords =
    root:
    let
      targetNames = directDirectories root;
    in
    builtins.concatLists (
      builtins.map (
        target:
        let
          targetRoot = root + "/${target}";
          entries = builtins.readDir targetRoot;
          hosts = builtins.filter (name: entries.${name} == "directory") (
            builtins.attrNames entries
          );
        in
        builtins.filter (record: record != null) (
          builtins.map (
            rawName:
            let
              hostRoot = targetRoot + "/${rawName}";
              hostEntries = builtins.readDir hostRoot;
              entrypoint = hostRoot + "/default.nix";
            in
            if hostEntries ? "default.nix" && hostEntries."default.nix" == "regular" then
              {
                inherit target;
                path = entrypoint;
                inherit rawName;
                private = lib.hasPrefix "_" rawName;
                name =
                  if lib.hasPrefix "_" rawName then lib.removePrefix "_" rawName else rawName;
              }
            else
              null
          ) hosts
        )
      ) targetNames
    );

  virtualType =
    target:
    let
      matches = builtins.filter (kind: lib.hasInfix kind target) [
        "do"
        "iso"
      ];
    in
    if matches == [ ] then null else builtins.head matches;

  systemRecords =
    let
      records = builtins.map (
        record:
        let
          type = virtualType record.target;
          darwin = type == null && lib.hasInfix "darwin" record.target;
          resolved =
            if type == null then
              record.target
            else
              lib.replaceStrings [ type ] [ "linux" ] record.target;
        in
        record
        // {
          system = resolved;
          format =
            if type != null then
              type
            else if darwin then
              "darwin"
            else
              "linux";
          virtual = type != null;
          kind =
            if type != null then
              "image"
            else if darwin then
              "darwin"
            else
              "nixos";
          output =
            if type != null then
              "${type}Configurations"
            else if darwin then
              "darwinConfigurations"
            else
              "nixosConfigurations";
        }
      ) (targetFirstRecords ./systems);
      names = builtins.map (record: record.name) records;
    in
    assert lib.assertMsg (
      builtins.length (lib.unique names) == builtins.length names
    ) "Duplicate normalized system names are not supported.";
    lib.listToAttrs (
      builtins.map (record: {
        inherit (record) name;
        value = record;
      }) records
    );

  homeRecords =
    let
      records = builtins.concatLists (
        builtins.map (
          target:
          let
            targetRoot = ./homes + "/${target}";
            entries = builtins.readDir targetRoot;
            children = builtins.filter (name: entries.${name} == "directory") (
              builtins.attrNames entries
            );
          in
          builtins.map
            (
              rawName:
              let
                child = targetRoot + "/${rawName}";
                name = if lib.hasInfix "@" rawName then rawName else "${rawName}@${target}";
                parts = lib.splitString "@" name;
              in
              {
                inherit target name;
                system = target;
                path = child + "/default.nix";
                user = builtins.head parts;
                host = if builtins.length parts > 1 then builtins.elemAt parts 1 else null;
              }
            )
            (
              builtins.filter (
                name:
                (builtins.readDir (targetRoot + "/${name}")) ? "default.nix"
                && (builtins.readDir (targetRoot + "/${name}"))."default.nix" == "regular"
              ) children
            )
        ) (directDirectories ./homes)
      );
    in
    lib.listToAttrs (
      builtins.map (record: {
        inherit (record) name;
        value = record;
      }) records
    );

  builderLib = lib.extend (_final: _previous: { liberion = repositoryLib; });
  repositoryLib =
    let
      importHelper =
        path:
        let
          value = import path;
        in
        if builtins.isFunction value then value { lib = builderLib; } else value;
    in
    lib.foldl' (acc: value: acc // value) { } (
      builtins.map importHelper (recursiveDefaultFiles ./lib)
    );

  exportedLib = {
    inherit (repositoryLib)
      darwin
      fs
      launchd
      module
      xorg
      ;
    inherit (lib) overrideDerivation;
    override = lib.mkOverride;
    inherit (repositoryLib.darwin.programs) mkOneCaskProgram mkOneMasAppProgram;
  };

  homeLib = builderLib.extend (
    _final: _previous: { hm = inputs.home-manager.lib.hm; }
  );

  moduleWrapper =
    path: metadata: args:
    let
      imported = import path;
      moduleArgs =
        (
          (args // { inherit builderLib; })
          // {
            lib = builderLib;
            inputs = flakeInputs;
            inherit namespace;
          }
          // (
            if metadata ? system then { pkgs = contexts.${metadata.system}.pkgs; } else { }
          )
        )
        // metadata;
    in
    (if builtins.isFunction imported then imported moduleArgs else imported)
    // {
      _file = path;
    };

  modulePaths = {
    nixos = recursiveDefaultFiles ./modules/nixos;
    darwin = recursiveDefaultFiles ./modules/darwin;
    home = recursiveDefaultFiles ./modules/home;
  };

  moduleName =
    root: path:
    let
      rootText = toString root;
      pathText = toString path;
      relative = builtins.substring ((builtins.stringLength rootText) + 1) (
        (builtins.stringLength pathText) - (builtins.stringLength rootText) - 1
      ) pathText;
      suffix = "/default.nix";
    in
    if relative == "default.nix" then "" else lib.removeSuffix suffix relative;

  moduleMap = platform: {
    "${platform}Modules" = lib.listToAttrs (
      builtins.map (path: {
        name = moduleName (./modules + "/${platform}") path;
        value = moduleWrapper path { };
      }) modulePaths.${platform}
    );
  };

  moduleOutputs = moduleMap "nixos" // moduleMap "darwin" // moduleMap "home";
  platformModules =
    platform: metadata:
    builtins.map (path: moduleWrapper path metadata) modulePaths.${platform};
  homeModuleValues = metadata: platformModules "home" metadata;

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
      localOverlay = import ./overlays/nixpkgs-unstable/default.nix {
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
          default = callPackage ./packages/default/default.nix;
          rice = callPackage ./packages/rice/default.nix;
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

  homesForHost =
    host: system:
    builtins.filter (
      home:
      (home.host == host)
      || (home.host == null && home.user == host && home.system == system)
    ) (builtins.attrValues homeRecords);

  homeBaseModule = home: {
    home.username = home.user;
    home.homeDirectory =
      if lib.hasInfix "darwin" home.system then
        "/Users/${home.user}"
      else
        "/home/${home.user}";
  };

  homeUserModules =
    spec: metadata:
    let
      matched = homesForHost spec.name spec.system;
      users = lib.listToAttrs (
        builtins.map (home: {
          name = home.user;
          value = {
            imports = [
              (homeBaseModule home)
              (moduleWrapper home.path (
                metadata
                // {
                  inherit (home) name;
                  inherit (home) user;
                  inherit (home) host;
                  format = "home";
                }
              ))
            ];
          };
        }) matched
      );
      systemUsers = lib.listToAttrs (
        builtins.map (home: {
          name = home.user;
          value = {
            name = home.user;
            home = (homeBaseModule home).home.homeDirectory;
          };
        }) matched
      );
    in
    {
      users.users = systemUsers;
      home-manager = {
        inherit users;
        sharedModules = homeModuleValues metadata;
        useGlobalPkgs = true;
      };
    };
  hostedHomeModule =
    spec: metadata:
    { config, ... }:
    let
      homeArgs = metadata // {
        osConfig = config;
        systemConfig = config;
      };
      homeModule = homeUserModules spec homeArgs;
    in
    homeModule
    // {
      home-manager = homeModule.home-manager // {
        extraSpecialArgs = homeArgs;
      };
    };

  buildVirtual =
    spec:
    let
      metadata = baseSystemMetadata spec;
      context = contexts.${spec.system};
      virtualModules =
        if spec.format == "iso" then
          [
            {
              imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix" ];
              isoImage.makeEfiBootable = true;
              isoImage.makeUsbBootable = true;
            }
          ]
        else
          [ ];
      config = nixpkgs.lib.nixosSystem {
        inherit (spec) system;
        inherit (context) pkgs;
        lib = builderLib;
        modules = [
          (moduleWrapper spec.path metadata)
        ]
        ++ platformModules "nixos" metadata
        ++ virtualModules;
        specialArgs = metadata;
      };
    in
    if spec.format == "do" then
      assert lib.assertMsg (config.config.system.build.images ? digital-ocean)
        "Virtual system images require nixpkgs with system.build.images.digital-ocean.";
      config.config.system.build.images.digital-ocean
    else if spec.format == "iso" then
      config.config.system.build.isoImage
    else
      throw "Unsupported virtual system format '${spec.format}'.";

  buildSystem =
    spec:
    let
      metadata = baseSystemMetadata spec;
      context = contexts.${spec.system};
      modules = [
        (moduleWrapper spec.path metadata)
        { networking.hostName = spec.name; }
      ]
      ++ platformModules (
        if spec.kind == "darwin" then "darwin" else "nixos"
      ) metadata;
    in
    if spec.virtual then
      buildVirtual spec
    else if spec.kind == "darwin" then
      inputs.darwin.lib.darwinSystem {
        inherit (spec) system;
        inherit (context) pkgs;
        lib = builderLib;
        modules = modules ++ [
          inputs.home-manager.darwinModules.home-manager
          (hostedHomeModule spec metadata)
        ];
        specialArgs = metadata;
      }
    else
      nixpkgs.lib.nixosSystem {
        inherit (spec) system;
        inherit (context) pkgs;
        lib = builderLib;
        modules = modules ++ [
          inputs.home-manager.nixosModules.home-manager
          (hostedHomeModule spec metadata)
        ];
        specialArgs = metadata;
      };

  systemOutputs =
    let
      built = lib.mapAttrs (_: buildSystem) systemRecords;
      namesFor =
        output: lib.filterAttrs (name: _: systemRecords.${name}.output == output) built;
    in
    {
      darwinConfigurations = namesFor "darwinConfigurations";
      nixosConfigurations = namesFor "nixosConfigurations";
      doConfigurations = namesFor "doConfigurations";
      isoConfigurations = namesFor "isoConfigurations";
    };

  buildHome =
    home: parent:
    let
      context = contexts.${home.system};
      parentArgs =
        if parent == null then
          { }
        else
          (parent.config.home-manager.extraSpecialArgs or { });
      metadata = {
        inherit (home) system;
        inherit (home) target;
        format = "home";
        virtual = false;
        inherit (home) name;
        inherit (home) user;
        inherit (home) host;
        systems = systemRecords;
        inputs = flakeInputs;
        inherit namespace;
        osConfig = if parent == null then null else parent.config;
        systemConfig = if parent == null then null else parent.config;
      }
      // parentArgs;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit (context) pkgs;
      lib = homeLib;
      modules = homeModuleValues metadata ++ [
        (homeBaseModule home)
        (moduleWrapper home.path metadata)
      ];
      extraSpecialArgs = metadata;
    };

  parentForHome =
    home:
    if home.host != null then
      let
        targetName =
          if home.system == "aarch64-darwin" then
            "darwinConfigurations"
          else
            "nixosConfigurations";
      in
      if
        systemOutputs ? "${targetName}" && systemOutputs.${targetName} ? "${home.host}"
      then
        systemOutputs.${targetName}.${home.host}
      else
        null
    else
      null;

  homeOutputs = {
    homeConfigurations = lib.mapAttrs (
      _: home: buildHome home (parentForHome home)
    ) homeRecords;
  };

  checkEntrypoint = ./checks/pre-commit-hooks/default.nix;
  compositionRegressionEntrypoint = ./checks/composition-regression/default.nix;
  shellEntrypoint = ./shells/default/default.nix;

  checkOutputs = lib.genAttrs realSystems (
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
    }
  );

  shellOutputs = lib.genAttrs realSystems (
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
    }
  );

  formatterOutputs = lib.genAttrs realSystems (
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
    }
  );

  activationAliases =
    system:
    lib.listToAttrs (
      builtins.map
        (home: {
          name = "homeConfigurations-${home.name}";
          value = flakeInputs.self.homeConfigurations.${home.name}.activationPackage;
        })
        (
          builtins.filter (home: home.system == system) (builtins.attrValues homeRecords)
        )
    );

  packageOutputs = lib.genAttrs realSystems (
    system: contexts.${system}.packageNamespace // activationAliases system
  );

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
          overlay = import ./overlays/nixpkgs-unstable/default.nix {
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
  inherit
    exportedLib
    homeOutputs
    moduleOutputs
    packageOutputs
    checkOutputs
    shellOutputs
    formatterOutputs
    systemOutputs
    contexts
    exportedOverlays
    ;
  pkgs = lib.genAttrs realSystems (system: contexts.${system}.channels);
  snowfall = {
    config = {
      inherit namespace;
      src = ./.;
    };
    raw-config = { inherit namespace; };
    user-lib = exportedLib;
  };
  templates = { };
}
