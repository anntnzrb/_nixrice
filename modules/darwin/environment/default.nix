{ lib, ... }: {
  imports = [
    (lib.liberion.fs.getFile "modules/shared/environment/default.nix")
  ];
}
