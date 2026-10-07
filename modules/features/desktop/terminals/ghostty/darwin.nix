{ lib, ... }: {
  imports = [ (lib.liberion.darwin.homebrewApps [ "ghostty" ]) ];
}
