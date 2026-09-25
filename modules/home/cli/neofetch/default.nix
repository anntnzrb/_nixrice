import ../../../toggle.nix "cli.neofetch" (
  { pkgs, lib, ... }:
  let
    inherit (lib.liberion.module) on;
  in
  {
    home.packages = [ pkgs.neofetch ];

    xdg.configFile = {
      "neofetch" = on // {
        source = ./config/neofetch;
        target = "neofetch";
        recursive = true;
      };
    };
  }
)
