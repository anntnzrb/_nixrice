{ inputs, processedFlake }:
let
  namespace = "liberion";
  supportedSystems = [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-linux"
  ];
  repositoryRoot = ../../..;
  nixRoot = repositoryRoot + "/nix";
  sourceRoot = nixRoot;
  repositoryInputs = builtins.removeAttrs inputs [ "self" ];
  inherit (repositoryInputs) nixpkgs;
  inherit (nixpkgs) lib;
  flakeInputs = repositoryInputs // {
    self = processedFlake // {
      outPath = repositoryRoot;
    };
  };

  directDirectories =
    directory:
    let
      entries = builtins.readDir directory;
    in
    builtins.filter (name: entries.${name} == "directory") (
      builtins.attrNames entries
    );

  recursiveDefaultFiles =
    directory:
    let
      walk =
        currentDirectory:
        let
          entries = builtins.readDir currentDirectory;
          names = builtins.attrNames entries;
        in
        builtins.concatLists (
          builtins.map (
            name:
            let
              path = currentDirectory + "/${name}";
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
    walk directory;

  targetFirstRecords =
    targetsRoot:
    let
      targetNames = directDirectories targetsRoot;
    in
    builtins.concatLists (
      builtins.map (
        target:
        let
          targetRoot = targetsRoot + "/${target}";
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
        targetFirstRecords (nixRoot + "/systems")
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
        !hasVirtualSuffix
        || (record.virtual && builtins.elem record.system supportedSystems)
      ) records)
      "Virtual targets must match <architecture>-do|iso for a supported Linux system.";
    assert lib.assertMsg (builtins.all (
      record: builtins.elem record.system supportedSystems
    ) records) "System targets must resolve to supported systems.";
    lib.listToAttrs (
      builtins.map (record: {
        inherit (record) name;
        value = record;
      }) records
    );

  homeRecords =
    let
      targets = directDirectories (nixRoot + "/homes");
      records = builtins.concatLists (
        builtins.map (
          target:
          let
            targetRoot = nixRoot + "/homes/${target}";
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
      target: builtins.elem target supportedSystems
    ) targets) "Home targets must belong to supported systems.";
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
      builtins.map importHelper (recursiveDefaultFiles (nixRoot + "/lib"))
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
    _final: _previous: { hm = repositoryInputs.home-manager.lib.hm; }
  );

  instantiateModule =
    packageContexts: path: metadata: args:
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
              { pkgs = packageContexts.${metadata.system}.pkgs; }
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
    nixos = recursiveDefaultFiles (nixRoot + "/modules/nixos");
    darwin = recursiveDefaultFiles (nixRoot + "/modules/darwin");
    home = recursiveDefaultFiles (nixRoot + "/modules/home");
  };

  moduleName =
    modulesRoot: path:
    let
      rootText = toString modulesRoot;
      pathText = toString path;
      relative = builtins.substring ((builtins.stringLength rootText) + 1) (
        (builtins.stringLength pathText) - (builtins.stringLength rootText) - 1
      ) pathText;
      suffix = "/default.nix";
    in
    if relative == "default.nix" then "" else lib.removeSuffix suffix relative;

  moduleOutputs =
    instantiateModule:
    let
      moduleMap = platform: {
        "${platform}Modules" = lib.listToAttrs (
          builtins.map (path: {
            name = moduleName (nixRoot + "/modules/${platform}") path;
            value = instantiateModule path { };
          }) modulePaths.${platform}
        );
      };
    in
    moduleMap "nixos" // moduleMap "darwin" // moduleMap "home";

  platformModules =
    instantiateModule: platform: metadata:
    builtins.map (path: instantiateModule path metadata) modulePaths.${platform};

  homeModuleValues =
    instantiateModule: metadata: platformModules instantiateModule "home" metadata;
in
{
  inherit
    builderLib
    exportedLib
    flakeInputs
    homeLib
    homeRecords
    homeModuleValues
    moduleOutputs
    modulePaths
    namespace
    nixRoot
    nixpkgs
    platformModules
    repositoryInputs
    repositoryLib
    repositoryRoot
    sourceRoot
    supportedSystems
    systemRecords
    instantiateModule
    ;
}
