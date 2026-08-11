{
  inputs,
  flakeInputs,
  homeLib,
  homeModuleValues,
  homeRecords,
  instantiateModule,
  namespace,
  packageContexts,
  systemOutputs,
  systemRecords,
}:
let
  inherit (inputs) home-manager;
  inherit (inputs.nixpkgs) lib;

  homeBaseModule = home: {
    home.username = home.user;
    home.homeDirectory =
      if lib.hasInfix "darwin" home.system then
        "/Users/${home.user}"
      else
        "/home/${home.user}";
  };

  buildHome =
    home: parent:
    let
      context = packageContexts.${home.system};
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
    home-manager.lib.homeManagerConfiguration {
      inherit (context) pkgs;
      lib = homeLib;
      modules = homeModuleValues metadata ++ [
        (homeBaseModule home)
        (instantiateModule home.path metadata)
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
in
{
  inherit homeOutputs;
}
