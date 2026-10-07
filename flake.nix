{
  description = "Liberion's Core";

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    let
      lib = nixpkgs.lib.extend (
        final: _: {
          liberion = import ./lib {
            lib = final;
            root = ./.;
          };
        }
      );

      nixpkgsArgs = {
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.difference ./. (lib.fileset.maybeMissing ./.git);
      };
    in
    # flake-parts' nixosModules and Clan's darwinModules options re-wrap each
    # module, which reorders list merges (systemPackages); export them raw.
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = { inherit lib; };
      }
      (
        { withSystem, ... }: {
          imports = [
            inputs.clan-core.flakeModules.default
            inputs.treefmt-nix.flakeModule
            inputs.git-hooks.flakeModule
            ./flake/dev.nix
          ];

          systems = [
            "x86_64-linux"
            "aarch64-darwin"
          ];

          perSystem = { system, pkgs, ... }: {
            _module.args.pkgs = import nixpkgs (nixpkgsArgs // { inherit system; });
            clan.pkgs = pkgs;
            treefmt.projectRoot = src;
            pre-commit.settings.rootSrc = lib.mkForce src;
          };

          flake = {
            clan = {
              imports = [ ./clan.nix ];
              specialArgs = {
                inherit
                  inputs
                  self
                  lib
                  nixpkgsArgs
                  ;
              };
            };

            homeConfigurations."${lib.liberion.identity.user}@wsl" =
              withSystem "x86_64-linux"
                (
                  { pkgs, ... }:
                  inputs.home-manager.lib.homeManagerConfiguration {
                    inherit pkgs lib;
                    extraSpecialArgs = { inherit inputs; };
                    modules = [
                      ./homes/wsl.nix
                      {
                        home = {
                          username = lib.liberion.identity.user;
                          homeDirectory = "/home/${lib.liberion.identity.user}";
                        };
                      }
                    ];
                  }
                );

            overlays.default = import ./overlays/default.nix { inherit inputs; };
          };
        }
      )
    // {
      nixosModules = lib.liberion.modules.nixos;
      darwinModules = lib.liberion.modules.darwin;
      homeModules = lib.liberion.modules.home;
    };

  inputs = {

    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core?ref=26.05&shallow=1";
      inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs = {
      follows = "clan-core/nixpkgs";
    };
    flake-parts = {
      follows = "clan-core/flake-parts";
    };
    treefmt-nix = {
      follows = "clan-core/treefmt-nix";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };

    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun-overlay = {
      url = "github:alleneubank/bun-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-compat.follows = "";
        flake-utils.inputs.systems.follows = "clan-core/systems";
      };
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };

    determinate = {
      url = "github:DeterminateSystems/determinate/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix.follows = "";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew/main";
    };

    nix-spotlight = {
      url = "github:anntnzrb/nix-spotlight/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-annt = {
      url = "github:anntnzrb/nixvim/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "clan-core/treefmt-nix";
        nixvim.inputs = {
          flake-parts.follows = "clan-core/flake-parts";
          systems.follows = "clan-core/systems";
        };
      };
    };

    ghostty-protesilaos = {
      url = "github:anhsirk0/ghostty-themes/main";
      flake = false;
    };

    rio-catppuccin = {
      url = "github:catppuccin/rio/main";
      flake = false;
    };

    rio-dracula = {
      url = "github:dracula/rio-terminal/main";
      flake = false;
    };

    yazi-flavors = {
      url = "github:yazi-rs/flavors/main";
      flake = false;
    };

    yazi-timu-macos = {
      url = "gitlab:aimebertrand/timu-macos-yazi/main";
      flake = false;
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions/master?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox-nix = {
      url = "github:heitoraugustoln/betterfox-nix/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "clan-core/flake-parts";
        systems.follows = "clan-core/systems";
      };
    };

  };
}
