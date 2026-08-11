{ config, inputs, ... }:
let
  composition = config.liberion.composition;
  inherit (composition)
    baseSystemMetadata
    builderLib
    contexts
    homeModuleValues
    homeRecords
    moduleWrapper
    nixpkgs
    platformModules
    systemRecords
    ;
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
      doConfigurations = namesFor "doConfigurations";
      isoConfigurations = namesFor "isoConfigurations";
    };
in
{
  config.liberion.composition = { inherit systemOutputs; };
}
