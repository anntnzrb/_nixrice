{ lib, ... }: {
  imports = [ (lib.liberion.darwin.homebrewApps [ "stremio" ]) ];
}
