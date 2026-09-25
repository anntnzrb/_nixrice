import ../../../toggle.nix "common.desktop" (
  { lib, ... }:
  let
    inherit (lib.liberion.module) on;
  in
  {
    services.gnome.gnome-keyring = on;
    programs.dconf = on;
    security.polkit = on;
  }
)
