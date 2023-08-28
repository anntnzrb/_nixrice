{
  description = "The core of it all, careful.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "github:nix-community/nur-combined?dir=repos/rycee/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    rec {
      # globals
      me = {
        nixHosts = "${self}/nix/hosts";
        nixHomes = "${self}/nix/home";

        dotfilesDir = "${self}/.files";
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import "${self}/shell.nix" { inherit pkgs; }
      );

      #overlays = import "${me.nixOverlays}" { inherit inputs; };

      nixosConfigurations = import "${me.nixHosts}/hosts.nix" {
        inherit
          self
          me
          inputs
          outputs
          nixpkgs;
      };
    };
}
