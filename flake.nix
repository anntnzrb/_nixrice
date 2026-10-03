{
  description = "Liberion's Core";

  outputs =
    {
      self,
      nixpkgs,
      clan-core,
      git-hooks,
      home-manager,
      treefmt-nix,
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

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./flake.nix
          ./clan.nix
          ./identity.nix
          ./justfile
          ./.agents
          ./.github
          ./bin
          ./homes
          ./lib
          ./machines
          ./modules
          ./overlays
          ./scripts
          ./tests
        ];
      };

      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule pkgsFor.${system} {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt = {
              enable = true;
              strict = true;
              width = 80;
            };
            shfmt = {
              enable = true;
              indent_size = 4;
              excludes = [ ".envrc" ];
            };
            just.enable = true;
          };
          settings.formatter.shfmt.options = [
            "-ln"
            "posix"
            "-bn"
            "-ci"
          ];
        }
      );
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

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check src;

        tests =
          let
            failures = import ./tests { inherit lib self; };
          in
          if failures == [ ] then
            pkgsFor.${system}.runCommand "liberion-tests"
              { nativeBuildInputs = [ pkgsFor.${system}.jq ]; }
              ''
                bash ${./tests/reconcile.sh} ${./modules/base/reconcile/reconcile.sh}
                touch $out
              ''
          else
            throw "tests failed:\n${lib.concatStringsSep "\n" failures}";

        pre-commit-check = git-hooks.lib.${system}.run {
          inherit src;
          hooks = {
            treefmt = {
              enable = true;
              package = treefmtEval.${system}.config.build.wrapper;
            };

            deadnix = {
              enable = true;
              args = [ "--warn-used-underscore" ];
              settings.edit = true;
            };

            statix.enable = true;

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

            zizmor = {
              enable = true;
              args = [ "--no-exit-codes" ];
            };
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
