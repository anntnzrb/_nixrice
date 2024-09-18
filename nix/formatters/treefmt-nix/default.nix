{
  projectRootFile = "flake.nix";
  programs = {
    nixpkgs-fmt.enable = true;
    prettier.enable = true;
    actionlint.enable = true;

    deadnix = {
      enable = true;
      no-underscore = true;
    };

    statix = {
      enable = true;
      disabled-lints = [ "repeated_keys" ];
    };
  };
}
