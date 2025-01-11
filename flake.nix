{
  description = "Liberion's Core";

  inputs = {
    # -------------------------------------------------------------------------
    # nix
    # -------------------------------------------------------------------------
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # self pkgs
    nurpkgs.url = "github:anntnzrb/nurpkgs/main";
    nurpkgs.inputs.systems.follows = "systems";

    # user environment manager
    home-manager.url = "github:nix-community/home-manager/release-24.11"; # NOTE: match nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-stable";

    # flake framework
    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs-stable";
    snowfall-lib.inputs.flake-compat.follows = "flake-compat";

    # collection of hardware modules for systems
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # generate images (iso, sd, amazon, ...)
    nixos-generators.url = "github:nix-community/nixos-generators/master";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs-stable";

    # pre-commit
    pre-commit-hooks.url = "github:cachix/git-hooks.nix/master";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks.inputs.gitignore.follows = "";

    # -------------------------------------------------------------------------
    # darwin
    # -------------------------------------------------------------------------
    # macOS support
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-stable";

    # nix-homebrew integration
    nix-homebrew.url = "github:zhaofengli/nix-homebrew/main";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs-stable";
    nix-homebrew.inputs.nix-darwin.follows = "darwin";

    # fix .app bundles
    mac-app-util.url = "github:hraban/mac-app-util/master";
    mac-app-util.inputs.flake-compat.follows = "flake-compat";

    # -------------------------------------------------------------------------
    # misc
    # -------------------------------------------------------------------------
    # Neovim
    neovim-annt.url = "github:anntnzrb/nvf/main";

    # Emacs
    emacs-overlay.url = "github:nix-community/emacs-overlay/master";

    # Firefox extensions (add-ons)
    firefox-addons.url = "github:nix-community/nur-combined/master?dir=repos/rycee/pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs-stable";
    firefox-addons.inputs.flake-utils.follows = "flake-utils";

    # -------------------------------------------------------------------------
    # follows
    # -------------------------------------------------------------------------
    systems.url = "github:nix-systems/default/main";
    flake-utils.url = "github:numtide/flake-utils/main";
    flake-utils.inputs.systems.follows = "systems";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      src = ./nix;

      snowfall =
        let
          codeName = "liberion";
        in
        {
          namespace = codeName;
          meta.name = codeName;
          meta.title = codeName;
        };

      overlays = [ inputs.emacs-overlay.overlays.default ];

      channels-config.allowUnfree = true;
    };
}
