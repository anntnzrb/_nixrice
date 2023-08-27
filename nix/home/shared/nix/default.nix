{ pkgs
, inputs
, ...
}: {
  nixpkgs.overlays = [ inputs.snowfall-flake.overlay ];

  home.packages = [ pkgs.snowfallorg.flake ];
}
