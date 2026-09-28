{
  description = "Liberion's Core";

  outputs =
    {
      self,
      nixpkgs,
      clan-core,
      git-hooks,
      home-manager,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      lib = nixpkgs.lib.extend (
        final: _: { liberion = import ./lib { lib = final; }; }
      );

      nixpkgsArgs = {
        config.allowUnfree = true;
        overlays = [
          inputs.nixpkgs-firefox-darwin.overlay
          self.overlays.default
        ];
      };

      pkgsFor = forAllSystems (
        system: import nixpkgs (nixpkgsArgs // { inherit system; })
      );

      specialArgs = {
        inherit
          inputs
          self
          lib
          nixpkgsArgs
          ;
      };

      clan = clan-core.lib.clan {
        inherit self specialArgs;
        imports = [ ./clan.nix ];
        pkgsForSystem = system: pkgsFor.${system};
      };
    in
    {
      clan = clan.config;
      inherit (clan.config) nixosConfigurations clanInternals;
      darwinConfigurations = clan.config.darwinConfigurations or { };

      homeConfigurations."${lib.liberion.identity.user}@wsl" =
        home-manager.lib.homeManagerConfiguration
          {
            pkgs = pkgsFor.x86_64-linux;
            inherit lib;
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
          };

      nixosModules = lib.liberion.modules.nixos;
      darwinModules = lib.liberion.modules.darwin;
      homeModules = lib.liberion.modules.home;

      overlays.default = import ./overlays/default.nix { inherit inputs; };

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        pkgs.writeShellApplication {
          name = "nixfmt-tracked";
          runtimeInputs = [
            pkgs.git
            pkgs.nixfmt
          ];
          text = ''
            git ls-files -z -- "*.nix" | xargs -0 nixfmt --strict --width=80 "$@"
          '';
        }
      );

      checks = forAllSystems (system: {
        tests =
          let
            failures = import ./tests { inherit lib self; };
          in
          if failures == [ ] then
            pkgsFor.${system}.runCommand "liberion-tests" { } "touch $out"
          else
            throw "tests failed:\n${lib.concatStringsSep "\n" failures}";

        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt = {
              enable = true;
              args = [
                "--strict"
                "--verify"
              ];
              settings.width = 80;
            };

            deadnix = {
              enable = true;
              args = [ "--warn-used-underscore" ];
              settings.edit = true;
            };

            statix.enable = true;

            shfmt = {
              enable = true;
              excludes = [ "\\.envrc$" ];
              settings = {
                language-dialect = "posix";
                indent = 4;
                binary-next-line = true;
                case-indent = true;
              };
            };

            shellcheck = {
              enable = true;
              args = [
                "--enable=all"
                "-a"
                "-x"
                "-P"
                "SCRIPTDIR"
              ];
            };

            actionlint.enable = true;
          };
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            name = "liberion-shell";
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            nativeBuildInputs = self.checks.${system}.pre-commit-check.enabledPackages ++ [
              clan-core.packages.${system}.clan-cli
              pkgs.just
            ];
          };
        }
      );
    };

  inputs = {

    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core?ref=26.05&shallow=1";
    };

    nixpkgs = {
      follows = "clan-core/nixpkgs";
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
      # keeps own nixpkgs: pinned nixvim breaks on ours (typescript-go rename)
      inputs = {
        flake-parts.follows = "clan-core/flake-parts";
        treefmt-nix.follows = "clan-core/treefmt-nix";
        git-hooks-nix.follows = "git-hooks";
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
      };
    };

    nixpkgs-firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
