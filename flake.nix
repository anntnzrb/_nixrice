{
  description = "The core of it all, careful.";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs =
    { self
    , nixpkgs-stable
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs-stable.lib.genAttrs [ "x86_64-linux" ];
    in
    rec {
      # globals
      me = {
        nixHosts = "${self}/nix/hosts";
        nixHomes = "${self}/nix/home";

        dotfilesDir = "${self}/.files";
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgs-stable.legacyPackages.${system};
        in import "${self}/shell.nix" { inherit pkgs; }
      );

      #overlays = import "${me.nixOverlays}" { inherit inputs; };

      nixosConfigurations = import "${me.nixHosts}" {
        inherit
          self
          me
          inputs
          outputs
          nixpkgs-stable;
      };
    };
}