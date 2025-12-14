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
      url = "https://github.com/anntnzrb/nurpkgs/archive/main.tar.gz";
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
      url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
    };

    nixos-wsl = {
      # NixOS support on WSL
      url = "https://github.com/nix-community/nixos-wsl/archive/main.tar.gz";
    };

    darwin = {
      # nix support on macOS (darwin)
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      # NOTE: match nixpkgs main ref.
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-homebrew = {
      ## darwin
      # homebrew integration for nix
      url = "https://github.com/zhaofengli/nix-homebrew/archive/main.tar.gz";
    };

    mac-app-util = {
      ## darwin
      # allows nix-managed programs to be indexed by macOS Spotlight
      url = "https://github.com/hraban/mac-app-util/archive/master.tar.gz";
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
      url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    };

    neovim-annt = {
      # annt's neovim
      url = "https://github.com/anntnzrb/nvf/archive/main.tar.gz";
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
