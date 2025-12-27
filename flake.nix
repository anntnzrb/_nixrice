{
  description = "Liberion's Core";

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      src = ./nix;

      snowfall = rec {
        namespace = "liberion";
        meta.name = namespace;
        meta.title = namespace;
      };

      overlays = [ inputs.emacs-overlay.overlays.default ];

      channels-config.allowUnfree = true;

      outputs-builder =
        channels:
        let
          inherit (channels) nixpkgs;
          inherit (nixpkgs.stdenv.hostPlatform) system;
          inherit (inputs.self.checks.${system}) pre-commit-hooks;
        in
        {
          formatter = nixpkgs.writeShellApplication {
            name = "formatter";
            runtimeInputs = pre-commit-hooks.enabledPackages;
            text = ''
              pre-commit run --all-files -c ${pre-commit-hooks.config.configFile}
            '';
          };
        };
    };

  inputs = {
    # -------------------------------------------------------------------------
    # nix & nixpkgs
    # -------------------------------------------------------------------------

    nixpkgs = {
      # main nixpkgs reference, most likely pointing to stable
      url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
    };

    nixpkgs-stable = {
      # stable version of nixpkgs
      url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
    };

    nixpkgs-unstable = {
      # unstable version of nixpkgs
      url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    };

    nurpkgs = {
      # self hosted nix expressions
      url = "github:anntnzrb/nurpkgs/main";
    };

    # -------------------------------------------------------------------------
    # tools
    # -------------------------------------------------------------------------

    snowfall-lib = {
      # snowfall-lib is an opinionated flake framework
      # it forces a predefined schema
      # url = "github:snowfallorg/lib/main";
      url = "github:anntnzrb/snowfall-lib/main";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    pre-commit-hooks = {
      # run hooks before committing
      # user for linting, formatting and more
      url = "github:cachix/git-hooks.nix/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.gitignore.follows = "";
    };

    # -------------------------------------------------------------------------
    # systems
    # -------------------------------------------------------------------------

    nixos-generators = {
      # is a collection of image builders (iso, sd, vm, ...)
      url = "github:nix-community/nixos-generators/master";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nixos-hardware = {
      # is a collection of hardware modules for systems
      url = "github:NixOS/nixos-hardware/master";
    };

    nixos-wsl = {
      # NixOS support on WSL
      url = "github:nix-community/NixOS-WSL/main";
    };

    darwin = {
      # nix support on macOS (darwin)
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      # NOTE: match nixpkgs main ref.
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    determinate = {
      # determinate nix-darwin module for custom nix settings
      url = "github:DeterminateSystems/determinate/main";
      inputs.nixpkgs.follows = "nixpkgs-stable";
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
      url = "github:nix-community/home-manager/release-25.11";

      # NOTE: match nixpkgs main ref.
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    home-manager-unstable = {
      # unstable version of home-manager
      # used for unmerged new modules
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    emacs-overlay = {
      # bleeding-edge GNU Emacs in nix
      url = "github:nix-community/emacs-overlay/master";
    };

    neovim-annt = {
      # annt's neovim
      url = "github:anntnzrb/nvf/main";
    };

    ghostty-protesilaos = {
      ## ghostty themes
      # protesilaos themes: modus-, ef-, ...
      url = "https://github.com/anhsirk0/ghostty-themes/archive/main.tar.gz";
      flake = false;
    };

    rio-catppuccin = {
      ## rio themes
      # catppuccin
      url = "https://github.com/catppuccin/rio/archive/main.tar.gz";
      flake = false;
    };

    rio-dracula = {
      ## rio themes
      # dracula
      url = "https://github.com/dracula/rio-terminal/archive/main.tar.gz";
      flake = false;
    };

    yazi-flavors = {
      # yazi themes
      url = "https://github.com/yazi-rs/flavors/archive/main.tar.gz";
      flake = false;
    };

    yazi-timu-macos = {
      ## yazi themes
      # timu-macos
      url = "https://gitlab.com/aimebertrand/timu-macos-yazi/-/archive/main/timu-macos-yazi-main.tar.gz";
      flake = false;
    };

    # -------------------------------------------------------------------------
    # browsers
    # -------------------------------------------------------------------------

    zen-browser = {
      # zen browser (firefox fork)
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      # addons (extensions) for firefox as nix expressions
      url = "gitlab:rycee/nur-expressions/master?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    betterfox-nix = {
      # Betterfox integration
      url = "github:heitoraugustoln/betterfox-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };
}
