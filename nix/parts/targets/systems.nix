{
  inputs,
  nixpkgs,
  builderLib,
  packageContexts,
  homeModuleValues,
  homeRecords,
  instantiateModule,
  platformModules,
  baseSystemMetadata,
  systemRecords,
}:
let
  inherit (inputs) home-manager;
  inherit (inputs.nixpkgs) lib;

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
              (instantiateModule home.path (
                metadata
                // {
                  inherit (home) name;
                  inherit (home) user;
                  inherit (home) host;
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

  buildSystem =
    spec:
    let
      metadata = baseSystemMetadata spec;
      context = packageContexts.${spec.system};
      modules = [
        (instantiateModule spec.path metadata)
        { networking.hostName = spec.name; }
      ]
      ++ platformModules (
        if spec.kind == "darwin" then "darwin" else "nixos"
      ) metadata;
    in
    if spec.kind == "darwin" then
      inputs.darwin.lib.darwinSystem {
        inherit (spec) system;
        inherit (context) pkgs;
        lib = builderLib;
        modules = modules ++ [
          home-manager.darwinModules.home-manager
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
          home-manager.nixosModules.home-manager
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
    };
in
{
  inherit systemOutputs;
}
