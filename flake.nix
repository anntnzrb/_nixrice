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
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # nixpkgs lib extended with the repository helpers (`lib.liberion.*`)
      lib = nixpkgs.lib.extend (
        final: _: { liberion = import ./lib { lib = final; }; }
      );

      # nixpkgs arguments shared by every package set: flake outputs, clan and
      # machines (modules/nixpkgs.nix)
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
        # vars generators and clanInternals evaluate machines with this instance
        pkgsForSystem = system: pkgsFor.${system};
      };
    in
    {
      clan = clan.config;
      inherit (clan.config) nixosConfigurations clanInternals;
      darwinConfigurations = clan.config.darwinConfigurations or { };

      # standalone homes for hosts without a managed system (NixOS-WSL on tampa)
      homeConfigurations."annt@wsl" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        inherit lib;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./homes/wsl.nix
          {
            home = {
              username = "annt";
              homeDirectory = "/home/annt";
            };
          }
        ];
      };

      nixosModules.default = ./modules;
      darwinModules.default = ./modules/darwin.nix;

      overlays.default = import ./overlays/default.nix { inherit inputs; };

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        # formats git-tracked nix files; extra args (e.g. --check) pass through
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
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # nix
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

            # shell
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

            # GH actions
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
          default = pkgs.mkShell {
            name = "liberion-shell";
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            # the hook tools (nixfmt, deadnix, statix, shellcheck, ...) plus the rest
            nativeBuildInputs = self.checks.${system}.pre-commit-check.enabledPackages ++ [
              clan-core.packages.${system}.clan-cli
              pkgs.just
              pkgs.nixd
            ];
          };
        }
      );
    };

  inputs = {
    # -------------------------------------------------------------------------
    # nix & nixpkgs
    # -------------------------------------------------------------------------

    clan-core = {
      # clan: machine inventory, deployment, vars & secrets
      url = "https://git.clan.lol/clan/clan-core/archive/26.05.tar.gz";
    };

    nixpkgs = {
      # stable nixpkgs is owned by clan-core to avoid evaluation drift
      follows = "clan-core/nixpkgs";
    };

    nixpkgs-unstable = {
      # unstable version of nixpkgs
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    # -------------------------------------------------------------------------
    # tools
    # -------------------------------------------------------------------------

    git-hooks = {
      # run hooks before committing
      # user for linting, formatting and more
      url = "github:cachix/git-hooks.nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      # rust toolchains (nightly/stable/beta)
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun-overlay = {
      # latest Bun binary package from official upstream releases
      url = "github:alleneubank/bun-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # -------------------------------------------------------------------------
    # systems
    # -------------------------------------------------------------------------

    nixos-hardware = {
      # is a collection of hardware modules for systems
      url = "github:NixOS/nixos-hardware/master";
    };

    nixos-wsl = {
      # NixOS support on WSL
      url = "github:nix-community/NixOS-WSL/main";
    };

    determinate = {
      # determinate nix-darwin module for custom nix settings
      url = "github:DeterminateSystems/determinate/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix.follows = "";
    };

    nix-homebrew = {
      ## darwin
      # homebrew integration for nix
      url = "github:zhaofengli/nix-homebrew/main";
    };

    nix-spotlight = {
      ## darwin
      # allows nix-managed programs to be indexed by macOS Spotlight
      url = "github:anntnzrb/nix-spotlight/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # -------------------------------------------------------------------------
    # misc
    # -------------------------------------------------------------------------

    home-manager = {
      # allows managing the environment at user level
      # provides modules for many programs
      url = "github:nix-community/home-manager/release-26.05";

      # NOTE: match nixpkgs main ref.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-annt = {
      # annt's neovim
      url = "github:anntnzrb/nixvim/main";
    };

    ghostty-protesilaos = {
      ## ghostty themes
      # protesilaos themes: modus-, ef-, ...
      url = "github:anhsirk0/ghostty-themes/main";
      flake = false;
    };

    rio-catppuccin = {
      ## rio themes
      # catppuccin
      url = "github:catppuccin/rio/main";
      flake = false;
    };

    rio-dracula = {
      ## rio themes
      # dracula
      url = "github:dracula/rio-terminal/main";
      flake = false;
    };

    yazi-flavors = {
      # yazi themes
      url = "github:yazi-rs/flavors/main";
      flake = false;
    };

    yazi-timu-macos = {
      ## yazi themes
      # timu-macos
      url = "gitlab:aimebertrand/timu-macos-yazi/main";
      flake = false;
    };

    # -------------------------------------------------------------------------
    # browsers
    # -------------------------------------------------------------------------

    zen-browser = {
      # zen browser (firefox fork)
      url = "github:0xc000022070/zen-browser-flake/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      # addons (extensions) for firefox as nix expressions
      url = "gitlab:rycee/nur-expressions/master?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    betterfox-nix = {
      # Betterfox integration
      url = "github:heitoraugustoln/betterfox-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-firefox-darwin = {
      # Firefox binary builds for macOS (official Mozilla DMGs)
      url = "github:bandithedoge/nixpkgs-firefox-darwin/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
