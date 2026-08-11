{ config, inputs, ... }:
let
  namespace = "liberion";
  realSystems = [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-linux"
  ];
  repositoryRoot = ../../..;
  root = repositoryRoot + "/nix";
  sourceRoot = root;
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  flakeInputs = (builtins.removeAttrs inputs [ "self" ]) // {
    self = config.processedFlake // {
      outPath = repositoryRoot;
    };
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

  targetInfo =
    target:
    let
      virtualMatch = builtins.match "^([^-]+)-(do|iso)$" target;
      type = if virtualMatch == null then null else builtins.elemAt virtualMatch 1;
      darwin = type == null && lib.hasSuffix "-darwin" target;
      resolved =
        if type == null then target else "${builtins.elemAt virtualMatch 0}-linux";
    in
    {
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
    };

  systemRecords =
    let
      records = builtins.map (record: record // targetInfo record.target) (
        targetFirstRecords (root + "/systems")
      );
      names = builtins.map (record: record.name) records;
    in
    assert lib.assertMsg (
      builtins.length (lib.unique names) == builtins.length names
    ) "Duplicate normalized system names are not supported.";
    assert lib.assertMsg
      (builtins.all (
        record:
        let
          hasVirtualSuffix =
            lib.hasSuffix "-do" record.target || lib.hasSuffix "-iso" record.target;
        in
        !hasVirtualSuffix || (record.virtual && builtins.elem record.system realSystems)
      ) records)
      "Virtual targets must match <architecture>-do|iso for a supported Linux system.";
    assert lib.assertMsg (builtins.all (
      record: builtins.elem record.system realSystems
    ) records) "System targets must resolve to supported realSystems.";
    lib.listToAttrs (
      builtins.map (record: {
        inherit (record) name;
        value = record;
      }) records
    );

  homeRecords =
    let
      targets = directDirectories (root + "/homes");
      records = builtins.concatLists (
        builtins.map (
          target:
          let
            targetRoot = root + "/homes/${target}";
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
        ) targets
      );
    in
    assert lib.assertMsg (builtins.all (
      target: builtins.elem target realSystems
    ) targets) "Home targets must belong to supported realSystems.";
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
      builtins.map importHelper (recursiveDefaultFiles (root + "/lib"))
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
            if metadata ? system then
              { pkgs = config.liberion.composition.contexts.${metadata.system}.pkgs; }
            else
              { }
          )
        )
        // metadata;
    in
    (if builtins.isFunction imported then imported moduleArgs else imported)
    // {
      _file = path;
    };

  modulePaths = {
    nixos = recursiveDefaultFiles (root + "/modules/nixos");
    darwin = recursiveDefaultFiles (root + "/modules/darwin");
    home = recursiveDefaultFiles (root + "/modules/home");
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
        name = moduleName (root + "/modules/${platform}") path;
        value = moduleWrapper path { };
      }) modulePaths.${platform}
    );
  };

  moduleOutputs = moduleMap "nixos" // moduleMap "darwin" // moduleMap "home";
  platformModules =
    platform: metadata:
    builtins.map (path: moduleWrapper path metadata) modulePaths.${platform};
  homeModuleValues = metadata: platformModules "home" metadata;
in
{
  config.liberion.composition = {
    inherit
      builderLib
      exportedLib
      flakeInputs
      homeLib
      homeModuleValues
      homeRecords
      moduleOutputs
      modulePaths
      moduleWrapper
      nixpkgs
      namespace
      realSystems
      repositoryLib
      root
      sourceRoot
      systemRecords
      platformModules
      ;
  };
}
