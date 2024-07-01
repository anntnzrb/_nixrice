{
  description = "Liberion's Core";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-stable";

    # flake framework
    snowfall-lib.url = "github:snowfallorg/lib/main";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs-stable";

    # collection of hardware modules for systems
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # generate NixOS images (iso, sd, amazon, ...)
    nixos-generators.url = "github:nix-community/nixos-generators/master";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs-stable";

    # user environment manager
    home-manager.url = "github:nix-community/home-manager/release-24.05"; # NOTE: match NixOS
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    # Firefox extensions (add-ons)
    firefox-addons.url = "github:nix-community/nur-combined/master?dir=repos/rycee/pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs-stable";

    # Neovim
    neovim-annt.url = "github:anntnzrb/nixvim/main";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      src = ./nix;

      snowfall =
        let
          codeName = "liberion";
        in
        {
          namespace = codeName;

          meta = {
            name = codeName;
            title = codeName;
          };
        };

      channels-config = {
        allowUnfree = true;
      };
    };
}
